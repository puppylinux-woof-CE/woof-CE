#include <signal.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <linux/uinput.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
	sigset_t set;
	struct uinput_setup setup = {.name = "altf1d"};
	struct input_event event = {0};
	int uinput, sig, ret = EXIT_FAILURE;

	if ((sigemptyset(&set) < 0) ||
	    (sigaddset(&set, SIGUSR1) < 0) ||
	    (sigaddset(&set, SIGTERM) < 0) ||
	    (sigprocmask(SIG_BLOCK, &set, NULL) < 0))
		return EXIT_FAILURE;

	uinput = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
	if (uinput < 0)
		return EXIT_FAILURE;

	if ((ioctl(uinput, UI_SET_EVBIT, EV_KEY) < 0) ||
	    (ioctl(uinput, UI_SET_KEYBIT, KEY_LEFTALT) < 0) ||
	    (ioctl(uinput, UI_SET_KEYBIT, KEY_F1) < 0) ||
	    (ioctl(uinput, UI_DEV_SETUP, &setup) < 0) ||
	    (ioctl(uinput, UI_DEV_CREATE) < 0)) {
		close(uinput);
		return EXIT_FAILURE;
	}

	while (sigwait(&set, &sig) == 0) {
		if (sig == SIGTERM) {
			ret = EXIT_SUCCESS;
			break;
		}

		event.type = EV_KEY;
		event.code = KEY_LEFTALT;
		event.value = 1;

		if (write(uinput, &event, sizeof(event)) != sizeof(event))
			break;

		event.code = KEY_F1;

		if (write(uinput, &event, sizeof(event)) != sizeof(event))
			break;

		event.type = EV_SYN;
		event.code = SYN_REPORT;
		event.value = 0;

		if (write(uinput, &event, sizeof(event)) != sizeof(event))
			break;

		event.type = EV_KEY;
		event.code = KEY_LEFTALT;
		event.value = 0;

		if (write(uinput, &event, sizeof(event)) != sizeof(event))
			break;

		event.code = KEY_F1;

		if (write(uinput, &event, sizeof(event)) != sizeof(event))
			break;
	}

	ioctl(uinput, UI_DEV_DESTROY);
	close(uinput);

	return ret;
}
