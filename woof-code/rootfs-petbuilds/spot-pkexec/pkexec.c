#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pwd.h>
#include <fcntl.h>
#include <paths.h>

int main(int argc, char *argv[])
{
	static char *ask[32] = {"/usr/sbin/run-as-spot", "/usr/sbin/pkexec-ask"};
	struct passwd *spot;
	const char *display, *wayland_display;
	int i, status, fd;
	pid_t pid;
	uid_t uid;
	gid_t gid;

	if ((argc == 1) || (argc > 30))
		return EXIT_FAILURE;

	display = getenv("DISPLAY");
	if (display && !display[0])
		return EXIT_FAILURE;

	wayland_display = getenv("WAYLAND_DISPLAY");
	if (!display && !wayland_display)
		return EXIT_FAILURE;

	if (wayland_display && !wayland_display[0])
		return EXIT_FAILURE;

	if (geteuid() != 0)
		return EXIT_FAILURE;

	uid = getuid();
	gid = getgid();

	if ((uid == 0) && (gid == 0))
		goto run;

	spot = getpwnam("spot");
	if (!spot ||
	    (uid != spot->pw_uid) ||
	    (gid != spot->pw_gid))
		return EXIT_FAILURE;

	for (i = 1; i < argc; ++i)
		ask[i + 1] = argv[i];

	for (fd = sysconf(_SC_OPEN_MAX); fd > STDERR_FILENO; --fd)
		close(fd);

	fd = open(_PATH_DEVNULL, O_RDWR);
	if (fd < 0)
		return EXIT_FAILURE;

	if (setuid(0) < 0) {
		close(fd);
		return EXIT_FAILURE;
	}

	pid = fork();
	if (pid == 0) {
		if ((dup2(fd, STDIN_FILENO) != STDIN_FILENO) ||
		    (dup2(fd, STDOUT_FILENO) != STDOUT_FILENO) ||
		    (dup2(fd, STDERR_FILENO) != STDERR_FILENO))
			exit(EXIT_FAILURE);

		if (chdir(spot->pw_dir) < 0)
			exit(EXIT_FAILURE);

		close(fd);

		clearenv();

		if (display && display[0])
			setenv("DISPLAY", display, 1);

		if (wayland_display && wayland_display[0])
			setenv("WAYLAND_DISPLAY", wayland_display, 1);

		execv(ask[0], ask);
		exit(EXIT_FAILURE);
	}
	else if (pid < 0) {
		close(fd);
		return EXIT_FAILURE;
	}

	close(fd);

	if (waitpid(pid, &status, 0) != pid)
		return EXIT_FAILURE;

	if (!WIFEXITED(status) || (WEXITSTATUS(status) != EXIT_SUCCESS))
		return EXIT_FAILURE;

run:
	execvp(argv[1], &argv[1]);
	return EXIT_FAILURE;
}