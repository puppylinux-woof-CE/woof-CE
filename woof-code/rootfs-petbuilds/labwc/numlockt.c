#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <linux/uinput.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
	struct uinput_setup setup = {.name = "numlockt"};
	struct input_event ev;
	int uinput, i;

	uinput = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
	if (uinput < 0) {
		return EXIT_FAILURE;
	}

	if ((ioctl(uinput, UI_SET_EVBIT, EV_KEY) < 0) ||
		(ioctl(uinput, UI_SET_EVBIT, EV_SYN) < 0) ||
		(ioctl(uinput, UI_SET_KEYBIT, KEY_NUMLOCK) < 0) ||
		(ioctl(uinput, UI_DEV_SETUP, &setup) < 0) ||
		(ioctl(uinput, UI_DEV_CREATE) < 0)) {
		close(uinput);
		return EXIT_FAILURE;
	}

	for(i=1; i>=0; i--) {
		usleep(200000);
		ev.type = EV_KEY;
		ev.code = KEY_NUMLOCK;
		ev.value = i;

		if (write(uinput, &ev, sizeof(ev)) != sizeof(ev)) {
			return EXIT_FAILURE;
		}
	}

	ev.type = EV_SYN;
	ev.code = 0;
	ev.value = 1;

	if (write(uinput, &ev, sizeof(ev)) != sizeof(ev)) {
		return EXIT_FAILURE;
	}

	ioctl(uinput, UI_DEV_DESTROY);
	close(uinput);

	return EXIT_SUCCESS;

}
