#include <time.h>
#include <sys/timex.h>

int adjtimex(struct timex *buf)
{
	buf->status |= STA_UNSYNC;
	return clock_adjtime(CLOCK_REALTIME, buf);
}
