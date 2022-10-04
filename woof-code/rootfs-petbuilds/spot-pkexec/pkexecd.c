#include <syscall.h>
#include <sys/types.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>

static inline
int pidfd_open(pid_t pid, unsigned int flags)
{
	return syscall(__NR_pidfd_open, pid, flags);
}

static inline
int pidfd_getfd(int pidfd, int targetfd, unsigned int flags)
{
	return syscall(__NR_pidfd_getfd, pidfd, targetfd, flags);
}

static
void exec_child(const pid_t pid, char *argv[])
{
	int fd, i, pid_fd;

	if ((pid_fd = pidfd_open(pid, 0)) < 0) return;

	for (i = STDIN_FILENO; i <= STDERR_FILENO; ++i) {
		if ((fd = pidfd_getfd(pid_fd, i, 0)) < 0) {
			if (errno != ESRCH) return;
			continue;
		}
		if (dup2(fd, i) != i) return;
		close(fd);
	}

	close(pid_fd);

	execvp(argv[0], argv);
}

void run_cmd(const pid_t pid, char *buf, const size_t len)
{
	static char *argv[32] = {"/usr/sbin/pkexec-ask"};
	pid_t ask, reaped;
	int argc, status;

	for (argc = 2, argv[1] = buf; argc < 31; ++argc) {
		if (!(argv[argc] = memchr(argv[argc - 1], '\0', len - (argv[argc] - buf)))) break;
		else if (argv[argc] < &buf[len - 2]) ++(argv[argc]);
		else {
			argv[argc] = NULL;
			if ((ask = fork()) == 0) {
				execv(argv[0], argv);
				exit(EXIT_FAILURE);
			} else if (ask > 0) {
				while ((reaped = waitpid(ask, &status, 0)) != ask) {
					if (reaped < 0) {
						if (errno == EINTR) continue;
						return;
					}
				}
				if (!WIFEXITED(status) || (WEXITSTATUS(status) != EXIT_SUCCESS))
					return;

				exec_child(pid, &argv[1]);
			}
			break;
		}
	}
}

static
void handle(const pid_t pid, const int fd)
{
	static char buf[1024];
	ssize_t chunk, total;

	for (total = 0; total < sizeof(buf);) {
		if ((chunk = recv(fd, &buf[total], sizeof(buf) - total, 0)) < 0) {
			if (errno == EINTR) continue;
			break;
		}
		else if (chunk == 0) break;
		total += (size_t)chunk;
		if (total > 2 && buf[total - 2] == '\0' && buf[total - 1] == '\0') {
			run_cmd(pid, buf, total);
			break;
		}
	}
}

int main(int argc, char *argv[])
{
	struct sockaddr_un sun = {.sun_family = AF_UNIX, .sun_path = "/tmp/pkexecd.socket"};
	struct ucred cred;
	pid_t pid, reaped;
	int s, c;
	socklen_t len = sizeof(cred);

	if ((s = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0)) < 0) return EXIT_FAILURE;
	if (bind(s, (const struct sockaddr *)&sun, sizeof(sun)) < 0) {
		if (errno != EADDRINUSE || (unlink(sun.sun_path) < 0 && errno != ENOENT) || bind(s, (const struct sockaddr *)&sun, sizeof(sun)) < 0) {
			close(s);
			return EXIT_FAILURE;
		}
	}
	if (chmod(sun.sun_path, 0766) < 0 || listen(s, 5) < 0) {
		close(s);
		unlink(sun.sun_path);
		return EXIT_FAILURE;
	}

	while (1) {
		if ((c = accept4(s, NULL, NULL, SOCK_CLOEXEC)) < 0) continue;
		if ((pid = fork()) == 0) {
			close(s);

			if (setsid() < 0) goto done;
			if ((pid = fork()) > 0) {
				close(c);
				return EXIT_SUCCESS;
			}
			else if (pid < 0) goto done;

			if (getsockopt(c, SOL_SOCKET, SO_PEERCRED, &cred, &len) < 0 || len != sizeof(cred)) goto done;

			handle(cred.pid, c);

done:
			close(c);
			return EXIT_FAILURE;
		} else if (pid > 0) {
			while ((reaped = waitpid(pid, NULL, 0)) != pid) {
				if (reaped < 0) {
					if (errno == EINTR) continue;
					break;
				}
			}
			close(c);
		}
	}

	close(s);
	unlink(sun.sun_path);
	return EXIT_FAILURE;
}
