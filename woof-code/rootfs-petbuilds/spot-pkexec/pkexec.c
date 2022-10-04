#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

static
int sendall(const int s, const char *buf, const size_t len)
{
	size_t total;
	ssize_t sent;

	for (total = 0; total < len; total += (size_t)sent) {
		sent = send(s, buf + total, len - total, MSG_NOSIGNAL);
		if (sent <= 0)
			return -1;
	}

	return 0;
}

int main(int argc, char *argv[])
{
	struct sockaddr_un sun = {.sun_family = AF_UNIX, .sun_path = "/tmp/pkexecd.socket"};
	size_t len;
	int s, i;

	if (argc == 1 || argc > 30)
		return EXIT_FAILURE;

	if (getuid() == 0 && getgid() == 0) {
		execvp(argv[1], &argv[1]);
		return EXIT_FAILURE;
	}

	if ((s = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0)) < 0) return EXIT_FAILURE;

	if (connect(s, (const struct sockaddr *)&sun, sizeof(sun))) {
		close(s);
		return EXIT_FAILURE;
	}

	for (i = 1; i < argc; ++i) {
		len = strlen(argv[i]);
		if ((len > 0 && sendall(s, argv[i], len) < 0) || sendall(s, "\0", 1) < 0) {
			close(s);
			return EXIT_FAILURE;
		}
	}
	if (sendall(s, "\0", 1) < 0) {
		close(s);
		return EXIT_FAILURE;
	}

	recv(s, &i, 1, 0);

	close(s);
	return EXIT_SUCCESS;
}
