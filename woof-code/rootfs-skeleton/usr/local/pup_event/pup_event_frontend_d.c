/*
*
* BK GPL3
* libc ref: http://www.gnu.org/software/libc/manual/html_node/Function-Index.html#Function-Index
*
* path:
*	/usr/local/pup_event/pup_event_frontend_d
*
* compile:
*	gcc -o pup_event_frontend_d pup_event_frontend_d.c
*	strip pup_event_frontend_d
*
*/

#include <stdlib.h>        // getenv(), system()
#include <sys/types.h>
#include <sys/socket.h>    // AF_NETLINK, bind()
#include <linux/netlink.h> // struct sockaddr_nl
#include <poll.h>          // poll(), struct pollfd
#include <unistd.h>        // getpid()
#include <string.h>        // strstr() etc..
#include <stdio.h>
#include <regex.h>         // regcomp()
#include <dirent.h>        // opendir(), readdir()

#define __SIGNALS 1

#if __SIGNALS
#include <signal.h>
#endif

int debug = 0;
char log2file = 0;
char logfile[] = "/tmp/pup_event_frontend_d.log";
char *app_name = NULL;
FILE *outf = NULL;

#define trace(...) { fprintf (outf, __VA_ARGS__); }

void cleanup(void) {
	if (log2file && outf) {
		fclose(outf);
	}
}

#if __SIGNALS
void signal_callback_handler(int signum) {
	if (outf) {
		fprintf(outf, "Caught signal %d\n",signum);
		cleanup;
	}
	exit(signum);
}
#endif

// -----------------------------------------------------------------------

int main(int argc, char **argv) {

#if __SIGNALS // http://www.cplusplus.com/reference/csignal/
	signal(SIGINT, signal_callback_handler);
	signal(SIGTERM, signal_callback_handler);
#endif

	outf = stderr;

	app_name = strrchr(argv[0], '/');
	if (app_name) {
		app_name++;
	} else {
		app_name = argv[0];
	}

	int i;
	for (i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-debug") == 0) {
			debug = 1;
		}
		else if (strcmp(argv[i], "-log2file") == 0) {
			log2file = 1;
		}
		else if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "-help") || !strcmp(argv[i], "--help")) {
			printf("\n%s -debug|-log2file:\n\n", app_name);
			printf("  -debug    : print debug info\n");
			printf("  -log2file : log to %s\n",logfile);
			return 0;
		}
	}
	if (getenv("PUPEVENT_DEBUG"))    debug = 1;
	if (getenv("PUPEVENT_LOG2FILE")) log2file = 1;

	fprintf(stderr, "%s: starting...\n", app_name);

	if (log2file) {
		outf = fopen(logfile, "w");
		if (!outf) {
			return 1;
		}
		fprintf(stderr, "%s: logging to %s\n", app_name, logfile);
	}

	char buf[512] = "";
	char *bufin = NULL;
	int eventstatus = 0;
	int clientdescr = 0;

	struct sockaddr_nl nls;
	struct pollfd pfd;

	DIR *dir1;
	struct dirent *ent1;

	int ret = system("/usr/local/pup_event/frontend_startup");
	if (ret != 0) {
		trace("%s: exited with code: %d\n", app_name, WEXITSTATUS(ret));
		trace("%s: exiting...\n");
		cleanup;
		return 9;
	}

	// initialise the nls structure
	nls.nl_family = AF_NETLINK;
	nls.nl_pad = 0;
	nls.nl_pid = getpid();
	nls.nl_groups = -1;

	// Open hotplug event netlink socket...
	pfd.events = POLLIN;
	pfd.fd = socket(PF_NETLINK, SOCK_DGRAM, NETLINK_KOBJECT_UEVENT);
	if (pfd.fd == -1) {
		trace("%s: could not open netlink socket\n", app_name);
		cleanup;
		return 1;
	}

	// listen to netlink socket...
	int retval = bind(pfd.fd, (void *)&nls.nl_family, sizeof(nls));
	if (retval == -1) {
		trace("%s: could listen to netlink socket\n", app_name);
		cleanup;
		return 2;
	}

	int cnt = 0;
	char devevents[256] = "";
	char exe_change[512] = "";

	/* big loop */
	while (1) {
		// 2 second timeout... note, -1 is wait indefinitely.
		eventstatus = poll(&pfd, 1, 1000);
		if (debug) trace("eventstatus: %d\n", eventstatus);
		if (eventstatus == -1) {
			cleanup;
			return 3;
		}
		if (eventstatus == 0) {
			// one-second timeout.
			// graceful exit if shutdown X (see /usr/bin/restartwm,wmreboot,wmpoweroff)...
			if ( access( "/tmp/wmexitmode.txt", F_OK ) != -1 ) {
				// file exists
				trace("%s: found /tmp/wmexitmode.txt .. exiting\n", app_name);
				cleanup;
				return 8;
			}
			if (devevents[0]) {
				snprintf(exe_change, sizeof(exe_change), "/usr/local/pup_event/frontend_change %s", devevents);
				if (debug) trace("exe_change: %s\n", exe_change);
				system(exe_change);
				// also post block-drive events to any ipc client...
				// look for any files named /tmp/pup_event_ipc/block_* ...
				dir1 = opendir("/tmp/pup_event_ipc");
				if (dir1) {
					while (1) {
						ent1 = readdir(dir1);
						if (!ent1) {
							break;
						}
						char *off1 = strstr( (*ent1).d_name,"block_" );
						if (off1) {
							char clientfile[256];
							char outmsg[256];
							snprintf( clientfile, sizeof(clientfile), "/tmp/pup_event_ipc/%s", (*ent1).d_name );
							snprintf( outmsg, sizeof(outmsg), "%s\n", devevents);
							FILE *clientdescr = fopen(clientfile, "a");
							if (clientdescr) {
								//write(clientdescr, outmsg, strlen(outmsg));
								fprintf(clientdescr, outmsg);
								fclose(clientdescr);
							}
						}
					}
				}
				devevents[0] = 0;

			} else {
				// want to call a pup_event script every four seconds...
				cnt++;
				if (cnt >= 4) {
					system("/usr/local/pup_event/frontend_timeout");
					cnt = 0;
				}
			}
			continue;
		}

		// get the uevent...
		int len = recv(pfd.fd, buf, sizeof(buf), MSG_DONTWAIT);
		if (len == -1) {
			cleanup;
			return 4;
		}
		if (debug) trace("len: %d - buf: %s\n", len, buf);

		// process the uevent...
		// only add@, remove@, change@ uevents...
		char devevent[50] = "";
		if (buf[0] == 'a' && buf[1] == 'd' && buf[2]=='d') {
			strcpy(devevent, "add:");
		} else if (buf[0] == 'r' && buf[1] == 'e' && buf[2]=='m') {
			strcpy(devevent, "rem:");
		} else if (buf[0] == 'c' && buf[1] == 'h' && buf[2]=='a') {
			strcpy(devevent, "cha:");
		}
		if (!devevent[0]) {
			continue;
		}

		// want uevents that have "SUBSYSTEM=block"...
		// buf has a sequence of **zero-delimited** strings...
		i = 0;
		int flag_block=0;
		char devname[50] = "";
		bufin = buf;
		while (i < len) {
			if (debug) trace("bufin: %s\n", bufin);
			if (flag_block) {
				// ex: DEVNAME=sdc DEVTYPE=disk  ex2: DEVNAME=sdc1 DEVTYPE=partition
				char *isdevname = strstr(bufin,"DEVNAME");
				if (isdevname) {
					char *devname = strchr(bufin, '=') + 1; /* DEVNAME=sdc-> sdc */
					if (debug) trace("devname: %s\n", devname);
					// ignore loop or ram devices...
					regex_t regex;
					if (regcomp(&regex, "^sd|^mmc|^nvme|^sr", REG_EXTENDED|REG_NOSUB) != 0) {
						// no match
						regfree(&regex);
						break;
					}
					regfree(&regex);
					char tmp[256];
					strncpy(tmp, devevents, sizeof(tmp));
					snprintf(devevents, sizeof(devevents), "%s%s%s ", tmp, devevent, devname);
					if (debug) trace("[%s] %s\n", app_name, devevents);
				}
			} else {
				if (strcmp(bufin,"SUBSYSTEM=block") == 0) {
					flag_block = 1;
				}
			}
			i = i + strlen(bufin) + 1;
			bufin = bufin + strlen(bufin) + 1;
		}

	} /* end of big loop */

	cleanup;
	return 0;
}

/* EOF */