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

#define TYPE_NODISC	-1
#define TYPE_AUDIO	1
#define TYPE_DATA	2
#define TYPE_MIXED	50
#define TYPE_BLANK	100
#define TYPE_UNKNOWN	150

static struct {
	unsigned int verbose;
	unsigned int quiet;
	char device[255];
} opts = { 0, 0, CDDEVICE };

int cddetect_quick = 0;

void err_exit(const char *message, int exit_code) {
	if (!opts.quiet) {
		perror(message);
		printf("disc blank or damaged\n");
	}
	exit(exit_code);
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
	fprintf(stderr, "\t- (no disc)\t%3d\n", (unsigned int)TYPE_NODISC);
	fprintf(stderr, "\t- (blank or damaged)\t%3d\n", TYPE_BLANK);
	fprintf(stderr, "\t- unknown\t%3d\n", TYPE_UNKNOWN);
	exit(0);
}


int main(int argc, char *const *argv)
{
	int fd;
	int status;
	struct cdrom_tochdr th;
	int optchar;
	int cdtype = 0;

	while ((optchar = getopt(argc, argv, "hVd:vqf")) != EOF)
		switch (optchar) {
			case 'V': fprintf(stderr, "%s\n", vcid); exit(0); break;
			case 'd': strncpy(opts.device, optarg, sizeof(opts.device)); break;
			case 'v': opts.verbose++; break;
			case 'q': opts.quiet++; break;
			case 'f': cddetect_quick = 1; break;
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
		err_exit("open", TYPE_NODISC);
	}

	// read the drive status info
	status = ioctl(fd, CDROM_DRIVE_STATUS, CDSL_CURRENT);

	switch(status) {
		case CDS_NO_DISC:
			close(fd);
			if (!opts.quiet) printf("no disc!\n");
			return TYPE_NODISC;
			break;
		case CDS_TRAY_OPEN:
			close(fd);
			if (!opts.quiet) printf("tray open!\n");
			return TYPE_NODISC;
			break;
		case CDS_DRIVE_NOT_READY:
			close(fd);
			if (!opts.quiet) printf("drive not ready!\n");
			return TYPE_NODISC;
			break;
		case CDS_DISC_OK:
			if (cddetect_quick) {
				close(fd);
				if (!opts.quiet) printf("disc inserted\n");
				return 0;
			}
			// do nothing
			break;
		default: // unidentified problem
			close(fd);
			if (cddetect_quick) {
				if (!opts.quiet) printf("unidentified error\n");
				return TYPE_NODISC;
			} else {
				err_exit("getstatus", TYPE_NODISC);
			}
	}

	status = ioctl(fd, CDROMREADTOCHDR, &th);
	if (status != 0) {
		close(fd);
		err_exit("gettochdr", TYPE_BLANK);
	}

	status = ioctl(fd, CDROM_DISC_STATUS, CDSL_CURRENT);

	close(fd);

	if (!opts.quiet) printf("cdtype: ");

	switch (status) {
		case CDS_AUDIO:
			if (!opts.quiet) printf("audio\n");
			return TYPE_AUDIO;
			break;
		case CDS_DATA_1:
			if (!opts.quiet) printf("data mode 1\n");
			return TYPE_DATA;
			break;
		case CDS_DATA_2:
			if (!opts.quiet) printf("data mode 2\n");
			return TYPE_DATA;
			break;
		case CDS_MIXED:
			if (!opts.quiet) printf("mixed mode\n");
			return TYPE_MIXED;
			break;
		case CDS_XA_2_1:
			if (!opts.quiet) printf("xa\n");
			return TYPE_DATA;
			break;
		case CDS_XA_2_2:
			if (!opts.quiet) printf("cdi\n");
			return TYPE_DATA;
			break;
		default:
			if (!opts.quiet) printf("unknown\n");
			return TYPE_UNKNOWN;
			break;
	}
}
