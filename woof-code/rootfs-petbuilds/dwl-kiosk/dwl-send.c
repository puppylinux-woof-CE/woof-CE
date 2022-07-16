#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	static char buf[512];
	char *line;
	struct sockaddr_un sun = {.sun_family = AF_UNIX};
	int s;

	if (argc < 2) return EXIT_FAILURE;

	s = socket(AF_UNIX, SOCK_DGRAM, 0);
	if (s < 0) return EXIT_FAILURE;

	strncpy(sun.sun_path, argv[1], sizeof(sun.sun_path));
	sun.sun_path[sizeof(sun.sun_path) - 1] = '\0';

	while ((line = fgets(buf, sizeof(buf), stdin)))
		sendto(s, line, strlen(line), 0, (const struct sockaddr *)&sun, sizeof(sun));

	close(s);

	return EXIT_FAILURE;
}