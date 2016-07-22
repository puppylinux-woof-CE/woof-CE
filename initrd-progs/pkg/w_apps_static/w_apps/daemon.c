/*
 * this file is part of sdaemons.
 *
 * Copyright (c) 2015 Dima Krasner
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sched.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <paths.h>

#ifndef CLONE_NEWNS
#define CLONE_NEWNS	0x00020000
#endif

#define USAGE "Usage: %s ARG...\n"
#define PATH_RUN "/run"

int main(int argc, char *argv[])
{
	sigset_t mask;

	if (1 >= argc) {
		(void) fprintf(stderr, USAGE, argv[0]);
		goto end;
	}

	/* unblock all signals */
	if (-1 == sigemptyset(&mask))
		goto end;
	if (-1 == sigprocmask(SIG_UNBLOCK, &mask, NULL))
		goto end;

	/* clear the environment, to remove variables that can affect the daemon
	 * behavior (e.g LD_PRELOAD) */
	if (0 != clearenv())
		goto end;

	if (-1 == chdir(PATH_RUN))
		goto end;

	(void) umask(0);

	/* daemonize */
	switch (fork()) {
		case (-1):
			goto end;

		case 0:
			break;

		default:
			exit(EXIT_SUCCESS);
	}

	if (((pid_t) -1) == setsid())
		goto end;

	switch (fork()) {
		case (-1):
			goto end;

		case 0:
			break;

		default:
			exit(EXIT_SUCCESS);
	}

	if (-1 == unshare(CLONE_NEWNS))
		goto end;

	/* redirect all pipes to /dev/null */
	if (-1 == close(STDIN_FILENO))
		goto end;
	if (-1 == open(_PATH_DEVNULL, O_RDONLY))
		goto end;

	if (-1 == close(STDOUT_FILENO))
		goto end;
	if (-1 == open(_PATH_DEVNULL, O_WRONLY))
		goto end;
	if (STDERR_FILENO != dup2(STDOUT_FILENO, STDERR_FILENO))
		goto end;

	(void) execvp(argv[1], &argv[1]);

end:
	return EXIT_FAILURE;
}
