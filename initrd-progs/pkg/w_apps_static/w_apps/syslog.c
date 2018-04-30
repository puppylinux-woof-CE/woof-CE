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

#define _POSIX_C_SOURCE 200809L

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/klog.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef HAVE_WAIVE
#	include <waive.h>
#endif

#ifndef F_SETSIG
#define F_SETSIG	10	/* for sockets. */
#endif

#define MAX_MSG_LEN (1024)

#define PATH_DEVLOG "/dev/log"

#define PATH_SYSLOG "/var/log/syslog"

#define PATH_KLOG "/var/log/kern.log"

#define USAGE "Usage: %s\n"

static bool log_write(const int fd, char *buf, ssize_t len)
{
	ssize_t out;

	/* make sure the message ends with a line break */
	if ('\n' != buf[len - 1]) {
		buf[len] = '\n';
		buf[1 + len] = '\0';
		++len;
	}

	do {
		out = write(fd, buf, (size_t) len);
		if (-1 == out)
			return false;
		len -= out;
	} while (0 < len);

	return true;
}

static void close_klog(void *arg)
{
	(void) klogctl(7, NULL, 0);
	(void) klogctl(0, NULL, 0);
}

static void *klog_routine(void *arg)
{
	char buf[MAX_MSG_LEN];
	int len;
	int fd = (int) (intptr_t) arg;

	/* make the thread termination immediate, since klogctl() may block */
	if (0 != pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, NULL))
		goto end;

	/* open the kernel log and disable echo of messages to the console - do not
	 * allow termination of the thread until a cleanup handler is assigned */
	if (0 != pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL))
		goto end;

	if (-1 == klogctl(1, NULL, 0))
		goto end;

	if (-1 == klogctl(6, NULL, 0))
		goto close_klog;

	pthread_cleanup_push(close_klog, NULL);

	if (0 != pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL))
		goto close_klog;

	do {
		len = klogctl(2, buf, sizeof(buf));
		switch (len) {
			case (-1):
				goto close_klog;

			case 0:
				continue;

			default:
				/* do not allow termination of the thread during log_write(), to
				 * prevent truncation of log messages */
				if (0 != pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, NULL))
					goto close_klog;

				if (false == log_write(fd, buf, (ssize_t) len))
					goto close_klog;

				if (0 != pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, NULL))
					goto close_klog;
		}
	} while (1);

close_klog:
	pthread_cleanup_pop(1);

end:
	pthread_exit(NULL);
}

int main(int argc, char *argv[])
{
	char buf[MAX_MSG_LEN];
	struct sockaddr_un addr;
	pthread_t klog;
	sigset_t mask;
	ssize_t len;
	int syslog_fd;
	int klog_fd;
	int sock;
	int sig;
	int io_sig;
	int flags;
	int exit_code = EXIT_FAILURE;

	if (1 != argc) {
		(void) fprintf(stderr, USAGE, argv[0]);
		goto end;
	}

	io_sig = SIGRTMIN;

	if (-1 == sigemptyset(&mask))
		goto end;
	if (-1 == sigaddset(&mask, io_sig))
		goto end;
	if (-1 == sigaddset(&mask, SIGTERM))
		goto end;
	if (-1 == sigprocmask(SIG_SETMASK, &mask, NULL))
		goto end;

	syslog_fd = open(PATH_SYSLOG,
	                 O_WRONLY | O_APPEND | O_CREAT,
	                 S_IRUSR | S_IWUSR);
	if (-1 == syslog_fd)
		goto end;

	klog_fd = open(PATH_KLOG, O_WRONLY | O_APPEND | O_CREAT, S_IRUSR | S_IWUSR);
	if (-1 == klog_fd)
		goto close_syslog;

	sock = socket(AF_UNIX, SOCK_DGRAM, 0);
	if (-1 == sock)
		goto close_klog;

	addr.sun_family = AF_UNIX;
	(void) strcpy(addr.sun_path, PATH_DEVLOG);
	if (-1 == bind(sock,
	               (struct sockaddr *) &addr,
	               sizeof(addr)))
		goto close_sock;

	if (-1 == fcntl(sock, F_SETSIG, io_sig))
		goto close_sock;

	flags = fcntl(sock, F_GETFL);
	if (-1 == flags)
		goto close_sock;
	if (-1 == fcntl(sock, F_SETFL, flags | O_NONBLOCK | O_ASYNC))
		goto close_sock;
	if (-1 == fcntl(sock, F_SETOWN, getpid()))
		goto close_sock;

	if (0 != pthread_create(&klog,
	                        NULL,
	                        klog_routine,
	                        (void *) (intptr_t) klog_fd))
		goto close_sock;

#ifdef HAVE_WAIVE
	if (-1 == waive(WAIVE_UN |
	                WAIVE_INET |
	                WAIVE_PACKET |
	                WAIVE_CLONE |
	                WAIVE_EXEC |
	                WAIVE_PIPE))
		goto close_sock;
#endif

	do {
		if (0 != sigwait(&mask, &sig))
			break;

		if (SIGTERM == sig) {
			exit_code = EXIT_SUCCESS;
			break;
		}

		len = recv(sock, buf, sizeof(buf) - 2, 0);
		switch (len) {
			case (-1):
				if (EAGAIN != errno)
					goto stop_klog;

				/* fall through */

			case 0:
				continue;
		}

		if (false == log_write(syslog_fd, buf, len))
			break;
	} while (1);

stop_klog:
	(void) pthread_cancel(klog);
	(void) pthread_join(klog, NULL);

close_sock:
	(void) close(sock);
	(void) unlink(PATH_DEVLOG);

close_klog:
	(void) close(klog_fd);

close_syslog:
	(void) close(syslog_fd);

end:
	return exit_code;
}
