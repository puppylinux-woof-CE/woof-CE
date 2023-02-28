#include <sched.h>
#include <pthread.h>
#include <malloc.h>
#include <limits.h>

__attribute__((constructor))
static void init(void)
{
    cpu_set_t cpus;
    int ncpus;

    CPU_ZERO(&cpus);
    if (pthread_getaffinity_np(pthread_self(), sizeof(cpus), &cpus) == 0) {
        ncpus = CPU_COUNT(&cpus);
        if (ncpus > 0)
            mallopt(M_ARENA_MAX, ncpus);
    }

    mallopt(M_MMAP_THRESHOLD, 64 * 1024);
    mallopt(M_MXFAST, 32);
    mallopt(M_TOP_PAD, 64 * 1024);
    mallopt(M_TRIM_THRESHOLD, 64 * 1024);
}