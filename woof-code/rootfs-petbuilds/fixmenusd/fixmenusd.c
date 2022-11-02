#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <limits.h>
#include <sys/inotify.h>
#include <errno.h>
#include <string.h>
#include <signal.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <regex.h>
#include <stdio.h>

#define SPOTLIST "^(firefox|firefox-[a-z]+|google-chrome-[a-z]+|chromium|chromium-browser|vivaldi-[a-z]+|brave-browser|microsoft-edge-[a-z]+|transmission-[a-z]+|seamonkey|sylpheed|claws-mail|thunderbird|vlc|steam|code|librewolf|hexchat)$"

static int
sh(const char *cmd, const sigset_t *set)
{
	pid_t pid, reaped;

	pid = fork();
	if (pid == 0) {
		if (sigprocmask(SIG_SETMASK, set, NULL) == 0)
			execl("/bin/sh", "/bin/sh", "-c", cmd, (char *)NULL);

		exit(EXIT_FAILURE);
	}
	else if (pid > 0) {
		reaped = waitpid(pid, NULL, 0);
		if ((reaped == pid) || ((reaped < 0) && (errno == ECHILD)))
			return 0;

		return -1;
	}
	else
		return -1;
}

static void
setup_spot(const regex_t *re, const int bin, const struct inotify_event *event, const sigset_t *set, const int force)
{
	static char orig[NAME_MAX + sizeof(".bin")];
	struct stat stbuf;
	size_t len;
	char *cmd;

	if (force)
		goto doit;

	if (regexec(re, event->name, 0, NULL, 0) != 0)
		return;

	if (fstatat(bin, event->name, &stbuf, AT_SYMLINK_NOFOLLOW) < 0)
		return;

	if (((event->mask & IN_CREATE) && !S_ISLNK(stbuf.st_mode)) ||
	    (S_ISREG(stbuf.st_mode) && (stbuf.st_size == 0)))
		return;

doit:
	len = strlen(event->name);
	memcpy(orig, event->name, len);
	memcpy(orig + len, ".bin", sizeof(".bin"));

	if ((fstatat(bin, orig, &stbuf, AT_SYMLINK_NOFOLLOW) == 0) ||
	    (errno != ENOENT))
		return;

	if (asprintf(&cmd, "(setup-spot %s=true) &", event->name) < 0)
		return;
	sh(cmd, set);
	free(cmd);
}

static int
handle_events(const regex_t *re, const int fd, const int appwd, const int flatpakappwd, const int binwd, const int flatpakwd, const int flatpakbin, const int usrbin, const sigset_t *set)
{
	char buf[sizeof(struct inotify_event) + NAME_MAX + 1];
	const struct inotify_event *event;
	ssize_t out;
	size_t len;

	while (1) {
		out = read(fd, buf, sizeof(buf));
		if (out < 0) {
			if (errno == EAGAIN)
				break;

			return -1;
		}

		for (event = (const struct inotify_event *)buf;
		     (char *)event < (buf + out);
		     event = (const struct inotify_event *)((char *)event + sizeof(*event) + event->len)) {
			if (event->wd == binwd)
				setup_spot(re, usrbin, event, set, 0);
			else if (event->wd == flatpakwd)
				setup_spot(re, flatpakbin, event, set, 1);
			else if ((event->wd != appwd) && (event->wd != flatpakappwd))
				continue;

			if (!(event->mask & (IN_DELETE | IN_CLOSE_WRITE | IN_MOVED_TO)))
				continue;

			len = strlen(event->name);
			if ((len <= (sizeof(".desktop") - 1)) ||
			    (strcmp(&event->name[len - (sizeof(".desktop") - 1)], ".desktop") != 0))
				continue;

			alarm(5);
		}
	}

	return 0;
}

int
main(int argc, char* argv[])
{
	regex_t re;
	sigset_t set, oset;
	int fd, appwd, flatpakappwd, binwd, flatpakwd, flatpakbin, usrbin, sig;

	if (argc != 2)
		return EXIT_FAILURE;

	if ((sigemptyset(&set) < 0) ||
	    (sigaddset(&set, SIGRTMIN) < 0) ||
	    (sigaddset(&set, SIGALRM) < 0) ||
	    (sigaddset(&set, SIGINT) < 0) ||
	    (sigaddset(&set, SIGTERM) < 0) ||
	    (sigaddset(&set, SIGHUP) < 0) ||
	    (sigaddset(&set, SIGCHLD) < 0) ||
	    (sigprocmask(SIG_BLOCK, &set, &oset) < 0))
		return EXIT_FAILURE;

	if (regcomp(&re, SPOTLIST, REG_EXTENDED | REG_NOSUB) != 0)
		return EXIT_FAILURE;

	fd = inotify_init1(O_CLOEXEC);
	if (fd < 0) {
		regfree(&re);
		return EXIT_FAILURE;
	}

	appwd = inotify_add_watch(fd, "/usr/share/applications", IN_CLOSE_WRITE | IN_DELETE | IN_MOVED_TO | IN_EXCL_UNLINK);
	if (appwd < 0) {
		close(fd);
		regfree(&re);
		return EXIT_FAILURE;
	}

	flatpakappwd = inotify_add_watch(fd, "/var/lib/flatpak/exports/share/applications", IN_CREATE | IN_DELETE | IN_MOVED_TO | IN_EXCL_UNLINK);

	binwd = inotify_add_watch(fd, "/usr/bin", IN_CLOSE_WRITE | IN_CREATE | IN_MOVED_TO | IN_EXCL_UNLINK);
	if (binwd < 0) {
		inotify_rm_watch(fd, flatpakappwd);
		inotify_rm_watch(fd, appwd);
		close(fd);
		regfree(&re);
		return EXIT_FAILURE;
	}

	flatpakwd = inotify_add_watch(fd, "/var/lib/flatpak/exports/bin", IN_CREATE | IN_CREATE | IN_MOVED_TO | IN_EXCL_UNLINK);

	if (flatpakwd != -1) {
		flatpakbin = open("/var/lib/flatpak/exports/bin", O_DIRECTORY | O_RDONLY);
		if (flatpakbin < 0) {
			inotify_rm_watch(fd, flatpakwd);
			inotify_rm_watch(fd, binwd);
			inotify_rm_watch(fd, flatpakappwd);
			inotify_rm_watch(fd, appwd);
			close(fd);
			regfree(&re);
			return EXIT_FAILURE;
		}
	}

	usrbin = open("/usr/bin", O_DIRECTORY | O_RDONLY);
	if (usrbin < 0) {
		close(flatpakbin);
		inotify_rm_watch(fd, flatpakwd);
		inotify_rm_watch(fd, binwd);
		inotify_rm_watch(fd, flatpakappwd);
		inotify_rm_watch(fd, appwd);
		close(fd);
		regfree(&re);
		return EXIT_FAILURE;
	}

	if ((fcntl(fd, F_SETFL, O_NONBLOCK | O_ASYNC) < 0) ||
	    (fcntl(fd, F_SETSIG, SIGRTMIN) < 0) ||
	    (fcntl(fd, F_SETOWN, getpid()) < 0)) {
		close(usrbin);
		close(flatpakbin);
		inotify_rm_watch(fd, flatpakwd);
		inotify_rm_watch(fd, binwd);
		inotify_rm_watch(fd, flatpakappwd);
		inotify_rm_watch(fd, appwd);
		close(fd);
		regfree(&re);
		return EXIT_FAILURE;
	}

	while ((sigwait(&set, &sig) == 0) &&
	       (((sig == SIGRTMIN) &&
	         (handle_events(&re, fd, appwd, flatpakappwd, binwd, flatpakwd, flatpakbin, usrbin, &oset) == 0)) ||
	        ((sig == SIGALRM) &&
	         (sh(argv[1], &oset) == 0)) ||
	        (sig == SIGCHLD)));

	close(usrbin);
	close(flatpakbin);
	inotify_rm_watch(fd, flatpakwd);
	inotify_rm_watch(fd, binwd);
	inotify_rm_watch(fd, flatpakappwd);
	inotify_rm_watch(fd, appwd);
	close(fd);
	regfree(&re);
	return EXIT_FAILURE;
}