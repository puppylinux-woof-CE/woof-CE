#include <unistd.h>
#include <malloc.h>
#include <limits.h>

__attribute__((constructor))
static void init(void)
{
    long ncpus;

    ncpus = sysconf(_SC_NPROCESSORS_CONF);

    if ((ncpus > 0) && (ncpus <= INT_MAX))
        mallopt(M_ARENA_MAX, (int)ncpus);

    mallopt(M_MMAP_THRESHOLD, 64 * 1024);
    mallopt(M_MXFAST, 32);
    mallopt(M_TOP_PAD, 64 * 1024);
    mallopt(M_TRIM_THRESHOLD, 64 * 1024);
}