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
#include <unistd.h>        // getpid() access()
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
		cleanup();
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
	int eventstatus = 0;

	struct sockaddr_nl nls;
	struct pollfd pfd;

	int ret = system("/usr/local/pup_event/frontend_startup");
	if (ret != 0) {
		trace("%s: exited with code: %d\n", app_name, WEXITSTATUS(ret));
		trace("exiting...\n");
		cleanup();
		return 9;
	}

	// initialise the nls structure
	memset(&nls,0,sizeof(struct sockaddr_nl));
	nls.nl_family = AF_NETLINK;
	nls.nl_pid = getpid();
	nls.nl_groups = -1;

	// Open hotplug event netlink socket...
	pfd.events = POLLIN;
	pfd.fd = socket(PF_NETLINK, SOCK_DGRAM, NETLINK_KOBJECT_UEVENT);
	if (pfd.fd == -1) {
		trace("%s: could not open netlink socket\n", app_name);
		cleanup();
		return 1;
	}
	// listen to netlink socket...
	int retval = bind(pfd.fd, (void *)&nls, sizeof(struct sockaddr_nl));
	if (retval == -1) {
		trace("%s: could not listen to netlink socket\n", app_name);
		cleanup();
		return 2;
	}

	int cnt = 0;
	char exe_change[256] = "";

	/* big loop */
	while (1) {
		// 2 second timeout... note, -1 is wait indefinitely.
		eventstatus = poll(&pfd, 1, 1000);
		if (debug) trace("eventstatus: %d\n", eventstatus);
		if (eventstatus == -1) {
			cleanup();
			return 3;
		}
		if (eventstatus == 0) {
			// one-second timeout.
			// graceful exit if shutdown X (see /usr/bin/restartwm,wmreboot,wmpoweroff)...
			if ( access( "/tmp/wmexitmode.txt", F_OK ) != -1 ) {
				// file exists
				trace("%s: found /tmp/wmexitmode.txt .. exiting\n", app_name);
				cleanup();
				return 8;
			}
			// want to call a pup_event script every four seconds...
			cnt++;
			if (cnt >= 6) {
				if (debug) trace("/usr/local/pup_event/frontend_timeout\n");
				system("/usr/local/pup_event/frontend_timeout");
				cnt = 0;
			}
			continue;
		}

		cnt = 0;

		// get the uevent...
		int len = recv(pfd.fd, buf, sizeof(buf), MSG_DONTWAIT);
		if (len == -1) {
			cleanup();
			return 4;
		}
		// if (debug) trace("len: %d - buf: %s\n", len, buf);

		//add@/devices/pci0000:00/0000:00:1d.7/usb1/1-6/1-6:1.0/host33/target33:0:0/33:0:0:0/block/sdb
		//add@/devices/pci0000:00/0000:00:1d.7/usb1/1-6/1-6:1.0/host37/target37:0:0/37:0:0:0/block/sdb/sdb1
		char *block_str_pos = strstr(buf, "/block/");
		if (!block_str_pos) {
			continue;
		}
		// .../block/sdb        - ok
		// .../block/sdb/sdb1   - err
		char *drv = block_str_pos + 7; // sdb/sdb1
		if (strchr(drv, '/')) {
			continue;
		}
		if (debug) trace("drv: %s\n", drv);

		// process the uevent...
		// only add@, remove@, change@ uevents...
		if (strncmp(buf, "add", 3) == 0) {
			snprintf(exe_change, sizeof(exe_change), "/usr/local/pup_event/frontend_change add %s", drv);
		} else if (strncmp(buf, "remove", 6) == 0) {
			snprintf(exe_change, sizeof(exe_change), "/usr/local/pup_event/frontend_change remove %s", drv);
		} else if (strncmp(buf, "change", 6) == 0) {
			snprintf(exe_change, sizeof(exe_change), "/usr/local/pup_event/frontend_change change %s", drv);
		} else {
			continue;
		}

		if (debug) trace("exe_change: %s\n", exe_change);
		system(exe_change);

	} /* end of big loop */

	cleanup();
	return 0;
}

/* EOF */