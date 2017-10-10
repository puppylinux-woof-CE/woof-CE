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

#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/reboot.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/mount.h>
#include <paths.h>
#include <errno.h>

#define USAGE "Usage: %s\n"
#define CHILD_CMD "rc"

static pid_t start_child(void)
{
	sigset_t mask;
	pid_t pid;

	pid = fork();
	if (0 != pid)
		return pid;

	if (-1 == sigfillset(&mask))
		goto terminate;
	if (-1 == sigprocmask(SIG_UNBLOCK, &mask, NULL))
		goto terminate;

	(void) execlp(CHILD_CMD, CHILD_CMD, (char *) NULL);

terminate:
	exit(EXIT_FAILURE);

	/* not reached */
	return (-1);
}

int main(int argc, char *argv[])
{
	sigset_t mask;
	siginfo_t sig;
	pid_t child;
	int ret;

	if (1 != argc) {
		(void) fprintf(stderr, USAGE, argv[0]);
		goto end;
	}

	/* mount a devtmpfs file system at /dev, to make the controlling TTY device
	 * node accessible */
	if (-1 == mount("dev", _PATH_DEV, "devtmpfs", 0UL, NULL)) {
		if (EBUSY != errno)
			goto end;
	}

	/* block SIGCHLD, SIGUSR1 (poweroff) and SIGUSR2 (reboot) */
	if (-1 == sigemptyset(&mask))
		goto end;
	if (-1 == sigaddset(&mask, SIGUSR1))
		goto end;
	if (-1 == sigaddset(&mask, SIGUSR2))
		goto end;
	if (-1 == sigaddset(&mask, SIGCHLD))
		goto end;
	if (-1 == sigprocmask(SIG_SETMASK, &mask, NULL))
		goto end;

	sig.si_signo = SIGUSR2;

	child = start_child();
	if (-1 == child)
		goto shutdown;

	do {
		if (-1 == sigwaitinfo(&mask, &sig))
			break;

		if (SIGCHLD != sig.si_signo)
			break;

		if (sig.si_pid != waitpid(sig.si_pid, NULL, WNOHANG))
			break;

		/* stop the loop when the child process terminates */
		if (child == sig.si_pid)
			break;
	} while (1);

shutdown:
	/* kill all processes */
	ret = kill(-1, SIGTERM);
	(void) sleep(2);
	if (0 == ret)
		(void) kill(-1, SIGKILL);

	/* flush all file system buffers */
	sync();

	if (0 == vfork()) {
		if (SIGUSR1 == sig.si_signo)
			(void) reboot(RB_POWER_OFF);
		else
			(void) reboot(RB_AUTOBOOT);
	}

end:
	return EXIT_FAILURE;
}
