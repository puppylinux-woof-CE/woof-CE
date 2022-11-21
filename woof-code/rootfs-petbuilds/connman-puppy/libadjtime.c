#include <time.h>
#include <sys/timex.h>

int adjtimex(struct timex *buf)
{
	return clock_adjtime(CLOCK_REALTIME, buf);
}
