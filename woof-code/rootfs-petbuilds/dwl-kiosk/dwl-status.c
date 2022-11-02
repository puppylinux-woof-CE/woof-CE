#include <stdlib.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	static char buf[512];
	static struct {
		char title[256];
		char mon[32];
	} titles[8];
	char selmon[32] = "", output[32], layout[4];
	struct sockaddr_un sun = {.sun_family = AF_UNIX};
	ssize_t len;
	int s;
	unsigned int occ, sel, i, ntitles = 0, selocc = 0, seltags = 0;

	if (argc < 2) return EXIT_FAILURE;

	s = socket(AF_UNIX, SOCK_DGRAM, 0);
	if (s < 0) return EXIT_FAILURE;

	strncpy(sun.sun_path, argv[1], sizeof(sun.sun_path));
	sun.sun_path[sizeof(sun.sun_path) - 1] = '\0';
	if (bind(s, (const struct sockaddr *)&sun, sizeof(sun)) < 0 && (errno != EADDRINUSE || unlink(sun.sun_path) < 0 || bind(s, (const struct sockaddr *)&sun, sizeof(sun)) < 0)) {
		close(s);
		return EXIT_FAILURE;
	}

	setlinebuf(stdout);

	puts("1_sel|bool|true");
	puts("1_occ|bool|false");
	for (i = 2; i <= 9; ++i) {
		printf("%d_sel|bool|false\n", i);
		printf("%d_occ|bool|false\n", i);
	}
	puts("title|string|");
	puts("layout|string|");
	putchar('\n');

	while ((len = recvfrom(s, buf, sizeof(buf) - 1, 0, NULL, NULL)) > 0) {
		buf[len] = '\0';
		if (ntitles < 8 && sscanf(buf, "%31s title %255[^\n]", titles[ntitles].mon, titles[ntitles].title) == 2) {
			++ntitles;
			continue;
		}
		if (!selmon[0] && sscanf(buf, "%31s selmon %u", output, &sel) == 2) {
			if (sel) strcpy(selmon, output);
			continue;
		}
		if (selmon[0] && sscanf(buf, "%31s tags %u %u", output, &occ, &sel) == 3) {
			if (strcmp(output, selmon) == 0) {
				selocc = occ;
				seltags = sel;
			}
			continue;
		}
		if (!selmon[0] || sscanf(buf, "%31s layout %3s", output, layout) != 2 || strcmp(output, selmon) != 0) continue;
		for (i = 0; i < 9; ++i) {
			printf("%d_sel|bool|%s\n", i + 1, seltags & (1 << i) ? "true" : "false");
			printf("%d_occ|bool|%s\n", i + 1, selocc & (1 << i) ? "true" : "false");
		}
		for (i = 0; i < ntitles; ++i) {
			if (strcmp(titles[i].mon, selmon) == 0) {
				printf("title|string|%s\n", titles[i].title);
				goto layout;
			}
		}
		puts("title|string|");
layout:
		printf("layout|string|%s\n", layout);
		putchar('\n');
		ntitles = selocc = seltags = 0;
		selmon[0] = layout[0] = '\0';
	}

	close(s);
	unlink(sun.sun_path);

	return EXIT_FAILURE;
}