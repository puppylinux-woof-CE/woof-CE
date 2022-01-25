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
	int i;
	gboolean hold = FALSE;

	for (i = 1; i < argc; ++i) {
		if ((strcmp(argv[i], "-hold") == 0) || (strcmp(argv[1], "--hold") == 0)) {
			hold = TRUE;
			break;
		}
	}

	for (i = 1; i < argc; ++i) {
		if ((strcmp(argv[i], "-e") == 0) && (i < (argc - 1))) {
			cmd = g_strjoinv(" ", &argv[i + 1]);

			if (hold) {
				new_argv[3] = "/bin/sh";
				new_argv[4] = "-c";
				new_argv[5] = g_strdup_printf("%s; echo; echo -n \"FINISHED. PRESS ENTER KEY TO CLOSE THIS WINDOW: \"; read simuldone", cmd);
				g_free(cmd);
				new_argv[6] = NULL;

				execvp(new_argv[0], new_argv);
				g_free(new_argv[5]);
			}
			else {
				new_argv[3] = cmd;

				execvp(new_argv[0], new_argv);
				g_free(cmd);
			}

			return EXIT_FAILURE;
		}
	}

	argv[0] = new_argv[0];
	execvp(argv[0], argv);
	return EXIT_FAILURE;
}