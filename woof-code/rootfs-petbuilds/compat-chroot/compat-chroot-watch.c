#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <limits.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/inotify.h>
#include <stdlib.h>

static int
wrap_desktop(const char *root, FILE *in, FILE *out, const char *suffix)
{
	static char buf[1024];
	char *sep;
	size_t len;

	while (1) {
		errno = 0;
		if (!fgets(buf, sizeof(buf), in))
			break;

		if (strncmp(buf, "Exec=", sizeof("Exec=") - 1) == 0) {
			len = strlen(buf);
			if ((len > 1) && (buf[len - 1] == '\n'))
				buf[len - 1] = '\0';

			if (fprintf(out, "Exec=chroot %s run-as-spot sh -c '%s'\n", root, &buf[sizeof("Exec=") - 1]) <= 0)
				return -1;
		}
		else if (strncmp(buf, "TryExec=", sizeof("TryExec=") - 1) == 0)
			continue;
		else if (strncmp(buf, "Name=", sizeof("Name=") - 1) == 0) {
			len = strlen(buf);
			if ((len > 1) && (buf[len - 1] == '\n'))
				buf[len - 1] = '\0';

			if (fprintf(out, "Name=%s%s\n", &buf[sizeof("Name=") - 1], suffix) <= 0)
				return -1;
		}
		else if (strncmp(buf, "Name[", sizeof("Name[") - 1) == 0) {
			len = strlen(buf);
			if ((len > 1) && (buf[len - 1] == '\n'))
				buf[len - 1] = '\0';

			sep = strchr(buf, '=');
			if (sep) {
				*sep = '\0';

				if (fprintf(out, "%s=%s%s\n", buf, sep + 1, suffix) <= 0)
					return -1;
			}
			else if (!sep && (fputs(buf, out) == EOF))
				return -1;
		}
		else if (fputs(buf, out) == EOF)
			return -1;
	}

	if (errno)
		return -1;

	return 0;
}

static void
sh(const char *cmd)
{
	pid_t pid;

	pid = fork();
	if (pid == 0) {
		execl("/bin/sh", "/bin/sh", "-c", cmd, (char *)NULL);
		exit(EXIT_FAILURE);
	} else if (pid > 0)
		waitpid(pid, NULL, 0);
}

static int
handle_add(const char *root, int dapps, int apps, const char *desktop, const char *suffix)
{
	FILE *in, *out;
	int fd, ret;

	fd = openat(dapps, desktop, O_RDONLY);
	if (fd < 0)
		return -1;

	in = fdopen(fd, "r");
	if (!in) {
		close(fd);
		return -1;
	}

	fd = openat(apps, desktop, O_WRONLY | O_CREAT | O_TRUNC, 0600);
	if (fd < 0)
		return -1;

	out = fdopen(fd, "w");
	if (!out) {
		close(fd);
		fclose(in);
		return -1;
	}

	ret = wrap_desktop(root, in, out, suffix);
	fclose(out);
	fclose(in);
	if (ret < 0)
		unlinkat(apps, desktop, 0);

	return ret;
}

static int
handle_events(const char *root, int fd, int wd, int dapps, int apps, const char *reload, const char *suffix)
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
			len = strlen(event->name);

			if ((len <= (sizeof(".desktop") - 1)) ||
			    (strcmp(&event->name[len - (sizeof(".desktop") - 1)], ".desktop") != 0)) {
				continue;
			}

			if (event->mask & IN_DELETE) {
				if (unlinkat(apps, event->name, 0) == 0)
					sh(reload);
			}
			else if (event->mask & (IN_CREATE | IN_MOVED_TO)) {
				if (handle_add(root, dapps, apps, event->name, suffix) == 0)
					sh(reload);
			}
		}
	}

	return 0;
}

static void
cleanup(const char *root, DIR *dapps, DIR *apps, int dappsfd, int appsfd, const char *reload, const char *suffix)
{
	struct stat stbuf;
	struct dirent *ent;
	size_t len;
	int changed = 0;

	while (1) {
		ent = readdir(apps);
		if (!ent)
			break;

		if ((ent->d_type != DT_REG) && (ent->d_type != DT_LNK))
			continue;

		len = strlen(ent->d_name);
		if ((len <= (sizeof(".desktop") - 1)) ||
			(strcmp(&ent->d_name[len - (sizeof(".desktop") - 1)], ".desktop") != 0)) {
			continue;
		}

		if ((fstatat(dappsfd, ent->d_name, &stbuf, AT_SYMLINK_NOFOLLOW) < 0) &&
		    (errno == ENOENT) &&
		    (unlinkat(appsfd, ent->d_name, 0) == 0))
			changed = 1;
	};

	while (1) {
		ent = readdir(dapps);
		if (!ent)
			break;

		if ((ent->d_type != DT_REG) && (ent->d_type != DT_LNK))
			continue;

		len = strlen(ent->d_name);
		if ((len <= (sizeof(".desktop") - 1)) ||
			(strcmp(&ent->d_name[len - (sizeof(".desktop") - 1)], ".desktop") != 0)) {
			continue;
		}

		if ((fstatat(appsfd, ent->d_name, &stbuf, AT_SYMLINK_NOFOLLOW) < 0) &&
		    (errno == ENOENT) &&
		    (handle_add(root, dappsfd, appsfd, ent->d_name, suffix) == 0))
			changed = 1;
	};

	if (changed)
		sh(reload);
}

int
main(int argc, char* argv[])
{
	sigset_t set;
	DIR *apps, *dapps;
	int appsfd, dappsfd, fd, wd, sig;

	if (argc != 6)
		return EXIT_FAILURE;

	if ((sigemptyset(&set) < 0) ||
	    (sigaddset(&set, SIGRTMIN) < 0) ||
	    (sigaddset(&set, SIGINT) < 0) ||
	    (sigaddset(&set, SIGTERM) < 0) ||
	    (sigaddset(&set, SIGHUP) < 0) ||
	    (sigprocmask(SIG_BLOCK, &set, NULL) < 0))
		return EXIT_FAILURE;

	apps = opendir(argv[1]);
	if (!apps)
		return EXIT_FAILURE;

	appsfd = dirfd(apps);
	if (appsfd < 0)
		return EXIT_FAILURE;

	dapps = opendir(argv[2]);
	if (!dapps) {
		closedir(apps);
		return EXIT_FAILURE;
	}

	dappsfd = dirfd(dapps);
	if (dappsfd < 0) {
		closedir(dapps);
		closedir(apps);
		return EXIT_FAILURE;
	}

	cleanup(argv[3], dapps, apps, dappsfd, appsfd, argv[4], argv[5]);

	fd = inotify_init1(O_CLOEXEC);
	if (fd < 0) {
		closedir(apps);
		closedir(dapps);
		return EXIT_FAILURE;
	}

	wd = inotify_add_watch(fd, argv[2], IN_CREATE | IN_DELETE | IN_MOVED_TO | IN_EXCL_UNLINK);
	if (wd < 0) {
		close(fd);
		closedir(apps);
		closedir(dapps);
		return EXIT_FAILURE;
	}

	if ((fcntl(fd, F_SETFL, O_NONBLOCK | O_ASYNC) < 0) ||
	    (fcntl(fd, F_SETSIG, SIGRTMIN) < 0) ||
	    (fcntl(fd, F_SETOWN, getpid()) < 0)) {
		inotify_rm_watch(fd, wd);
		close(fd);
		closedir(apps);
		closedir(dapps);
		return EXIT_FAILURE;
	}

	while ((sigwait(&set, &sig) == 0) &&
	       (sig == SIGRTMIN) &&
	       (handle_events(argv[3], fd, wd, dappsfd, appsfd, argv[4], argv[5]) == 0));

	inotify_rm_watch(fd, wd);
	close(fd);
	closedir(apps);
	closedir(dapps);
	return EXIT_FAILURE;
}