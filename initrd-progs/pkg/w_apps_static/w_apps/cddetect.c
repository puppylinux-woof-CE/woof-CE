/*
 * bodo GPL v.2
 */

static char vcid[] = "$Id: cddetect.c,v 3.0 2018/03 bodo Exp $";

#include <sys/ioctl.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>
#include <linux/cdrom.h>

#define CDDEVICE "/dev/cdrom"

// exitcodes for CD

#define TYPE_UNKNOWN	-1
#define TYPE_AUDIO	1
#define TYPE_DATA	2
#define TYPE_MIXED	50

static struct {
	unsigned int verbose;
	unsigned int quiet;
	char device[255];
} opts = { 0, 0, CDDEVICE };

void err_exit(const char *message) {
	if (!opts.quiet) {
		perror(message);
	}
	exit(-1);
}

void usage(const char *progname)
{
	fprintf(stderr, "usage: %s -q|-v [-dDEVICE]\n", progname);
	fprintf(stderr, "       %s -h|-V\n", progname);
	fprintf(stderr, "\th get help\n");
	fprintf(stderr, "\tV show version\n");
	fprintf(stderr, "\tq quiet operation\n");
	fprintf(stderr, "\tv verbose operation\n");
	fprintf(stderr, "\td use device DEVICE, defaults to " CDDEVICE "\n\n");
	fprintf(stderr, "\tsets exit value according to detected cd type:\n");
	fprintf(stderr, "\t- audio\t\t%3d\n", TYPE_AUDIO);
	fprintf(stderr, "\t- data\t\t%3d\n", TYPE_DATA);
	fprintf(stderr, "\t- mixed\t\t%3d\n", TYPE_MIXED);
	exit(0);
}


int main(int argc, char *const *argv)
{
	int fd;
	int status;
	struct cdrom_tochdr th;
	int optchar;
	int cdtype = 0;

	while ((optchar = getopt(argc, argv, "hVd:vq")) != EOF)
		switch (optchar) {
			case 'V': fprintf(stderr, "%s\n", vcid); exit(0); break;
			case 'd': strncpy(opts.device, optarg, sizeof(opts.device)); break;
			case 'v': opts.verbose++; break;
			case 'q': opts.quiet++; break;
			case 'h':
			default: usage(argv[0]);
		}
	if (optind < argc) {
		usage(argv[0]);
	}
	if (opts.verbose > 0 && opts.quiet > 0) {
		usage(argv[0]);
	}
	fd = open(opts.device, O_RDONLY | O_NONBLOCK);
	if (fd < 0) {
		err_exit("open");
	}

	// read the drive status info
	status = ioctl(fd, CDROM_DRIVE_STATUS, CDSL_CURRENT);

	switch(status) {
		case CDS_NO_DISC:
			close(fd);
			if (!opts.quiet) printf("no disc!\n");
			return -1;
			break;
		case CDS_TRAY_OPEN:
			close(fd);
			if (!opts.quiet) printf("tray open!\n");
			return -1;
			break;
		case CDS_DRIVE_NOT_READY:
			close(fd);
			if (!opts.quiet) printf("drive not ready!\n");
			return -1;
			break;
		case CDS_DISC_OK:
			// do nothing
			break;
		default: // unidentified problem
			close(fd);
			err_exit("getstatus");
	}

	status = ioctl(fd, CDROMREADTOCHDR, &th);
	if (status != 0) {
		close(fd);
		err_exit("gettochdr");
	}

	status = ioctl(fd, CDROM_DISC_STATUS, CDSL_CURRENT);

	close(fd);

	if (!opts.quiet) printf("cdtype: ");

	switch (status) {
		case CDS_AUDIO:
			cdtype = TYPE_AUDIO;
			if (!opts.quiet) printf("audio\n");
			break;
		case CDS_DATA_1:
			cdtype = TYPE_DATA;
			if (!opts.quiet) printf("data mode 1\n");
			break;
		case CDS_DATA_2:
			cdtype = TYPE_DATA;
			if (!opts.quiet) printf("data mode 2\n");
			break;
		case CDS_MIXED:
			cdtype = TYPE_MIXED;
			if (!opts.quiet) printf("mixed mode\n");
			break;
		case CDS_XA_2_1:
			cdtype = TYPE_DATA;
			if (!opts.quiet) printf("xa\n");
			break;
		case CDS_XA_2_2:
			cdtype = TYPE_DATA;
			if (!opts.quiet) printf("cdi\n");
			break;
		case CDS_NO_INFO:
			if (!opts.quiet) printf("NO INFO\n");
			break;
		case CDS_NO_DISC:
			if (!opts.quiet) printf ("NO DISC\n");
			break;
		default:
			if (!opts.quiet) printf("unknown\n");
			break;
	}

	return cdtype;
}
