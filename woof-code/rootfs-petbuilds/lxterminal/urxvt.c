#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <glib.h>
#include <glib/gprintf.h>

int main(int argc, char **argv)
{
	static char *new_argv[32] = {
		"lxterminal",
		"--no-remote",
		"-e"
	};
	gchar *cmd;
	int i, j;
	gboolean hold = FALSE;

	if (argc >= 32)
		goto proxy;

	for (i = 1; i < argc; ++i) {
		if ((strcmp(argv[i], "-hold") == 0) || (strcmp(argv[i], "--hold") == 0)) {
			hold = TRUE;
			break;
		}
	}

	for (i = 1; i < argc; ++i) {
		if ((strcmp(argv[i], "-e") == 0) && (i < (argc - 1))) {
			if (hold) {
				new_argv[3] = "/bin/sh";
				new_argv[4] = "-c";
				cmd = g_strjoinv(" ", &argv[i + 1]);
				new_argv[5] = g_strdup_printf("%s; echo; echo -n \"FINISHED. PRESS ENTER KEY TO CLOSE THIS WINDOW: \"; read simuldone", cmd);
				g_free(cmd);
				new_argv[6] = NULL;

				execvp(new_argv[0], new_argv);
				g_free(new_argv[5]);
			}
			else {
				for (++i, j = 3; i < argc; ++i, ++j)
					new_argv[j] = argv[i];

				execvp(new_argv[0], new_argv);
			}

			return EXIT_FAILURE;
		}
	}

proxy:
	argv[0] = new_argv[0];
	execvp(argv[0], argv);
	return EXIT_FAILURE;
}