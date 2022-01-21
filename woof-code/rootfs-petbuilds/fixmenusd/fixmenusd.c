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

static int
handle_events(const int fd)
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
	sigset_t set, oset;
	int fd, wd, sig;

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

	fd = inotify_init1(O_CLOEXEC);
	if (fd < 0)
		return EXIT_FAILURE;

	wd = inotify_add_watch(fd, "/usr/share/applications", IN_CLOSE_WRITE | IN_DELETE | IN_MOVED_TO | IN_EXCL_UNLINK);
	if (wd < 0) {
		close(fd);
		return EXIT_FAILURE;
	}

	if ((fcntl(fd, F_SETFL, O_NONBLOCK | O_ASYNC) < 0) ||
	    (fcntl(fd, F_SETSIG, SIGRTMIN) < 0) ||
	    (fcntl(fd, F_SETOWN, getpid()) < 0)) {
		inotify_rm_watch(fd, wd);
		close(fd);
		return EXIT_FAILURE;
	}

	while ((sigwait(&set, &sig) == 0) &&
	       ((sig == SIGRTMIN) &&
	        (handle_events(fd) == 0)) ||
	       ((sig == SIGALRM) &&
	        (sh(argv[1], &oset) == 0)) ||
	       (sig == SIGCHLD));

	inotify_rm_watch(fd, wd);
	close(fd);
	return EXIT_FAILURE;
}