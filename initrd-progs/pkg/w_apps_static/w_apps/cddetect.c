/*
 * bodo GPL v.2
 * 
 * https://elixir.bootlin.com/linux/v3.2/source/include/linux/cdrom.h
 * 
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

#define CDDEVICE "/dev/sr0"

// exitcodes for CD

#define DISC_TYPE_NODISC		-1
#define DISC_TYPE_CD_AUDIO		1
#define DISC_TYPE_DATA			2
#define DISC_TYPE_DVD			4
#define DISC_TYPE_CD_MIXED		50
#define DISC_TYPE_CD_BLANK		100
#define DISC_TYPE_DVD_BLANK		101
#define DISC_TYPE_UNKNOWN		150

enum {
	DRIVE_TYPE_CDROM,
	DRIVE_TYPE_CDBURNER,
	DRIVE_TYPE_DVDROM,
	DRIVE_TYPE_DVDBURNER,
	DRIVE_TYPE_UNKNOWN
};

static struct {
	unsigned int verbose;
	unsigned int quiet;
	char device[255];
} opts = { 0, 0, CDDEVICE };

int cddetect_quick = 0;
int print_dt = 0;

void err_exit(const char *message, int exit_code) {
	if (!opts.quiet) {
		perror(message);
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
	fprintf(stderr, "\t- audio cd\t\t%3d\n", DISC_TYPE_CD_AUDIO);
	fprintf(stderr, "\t- data\t\t\t%3d\n", DISC_TYPE_DATA);
	fprintf(stderr, "\t- dvd\t\t\t%3d\n", DISC_TYPE_DVD);
	fprintf(stderr, "\t- mixed cd\t\t%3d\n", DISC_TYPE_CD_MIXED);
	fprintf(stderr, "\t- (no disc)\t\t%3d\n", DISC_TYPE_NODISC);
	fprintf(stderr, "\t- blank or damaged cd\t%3d\n", DISC_TYPE_CD_BLANK);
	fprintf(stderr, "\t- blank or damaged dvd\t%3d\n", DISC_TYPE_DVD_BLANK);
	fprintf(stderr, "\t- unknown\t\t%3d\n", DISC_TYPE_UNKNOWN);
	exit(0);
}

int get_drive_type(int fd) {
	int c;
	if ( (c=ioctl(fd,CDROM_GET_CAPABILITY,0)) >= 0 ) {
		if (c & CDC_DVD) {
			if ((c & CDC_DVD_R) || (c & CDC_DVD_RAM)) {
				return DRIVE_TYPE_DVDBURNER ;
			} else {
				return DRIVE_TYPE_DVDROM;
			}
		} else if (c & CDC_CD_R) {
			if (c & CDC_CD_RW) {
				return DRIVE_TYPE_CDBURNER;
			} else {
				return DRIVE_TYPE_UNKNOWN;
			}
		}
	}
	return DRIVE_TYPE_UNKNOWN;
}

//===========================================================================

int main(int argc, char **argv)
{
	int fd, i, drive_type, disc_type;
	int status;

	disc_type = DISC_TYPE_UNKNOWN;

	for (i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-V") == 0 ) {
			fprintf(stderr, "%s\n", vcid);
			return 0;
		} else if (strcmp(argv[i], "-v") == 0) {
			opts.verbose++;
			continue;
		} else if (strcmp(argv[i], "-q") == 0) {
			opts.quiet++;
			continue;
		} else if (strcmp(argv[i], "-f") == 0) {
			cddetect_quick = 1;
			continue;
		} else if (strcmp(argv[i], "-drive-type") == 0) {
			print_dt = 1;
			continue;
		} else if (strcmp(argv[i], "-d") == 0) {
			i++;
			if (i < argc) {
				strncpy(opts.device, argv[i], sizeof(opts.device));
				continue;
			}
		} else if (argv[i][0] == '-' && argv[i][1] == 'd') {
			if (strlen(argv[i]) > 2) {
				strncpy(opts.device, argv[i]+2, sizeof(opts.device));
				continue;
			}
		}
		usage(argv[0]);
	}

	fd = open(opts.device, O_RDONLY | O_NONBLOCK);
	if (fd < 0) {
		err_exit("open", DISC_TYPE_NODISC);
	}

	drive_type = get_drive_type(fd);

	if (print_dt) {
		switch (drive_type) {
			case DRIVE_TYPE_CDROM:     printf("cdrom\n");     break;
			case DRIVE_TYPE_CDBURNER:  printf("dvdburner\n"); break;
			case DRIVE_TYPE_DVDROM:    printf("dvdrom\n");    break;
			case DRIVE_TYPE_DVDBURNER: printf("cdburner\n");  break;
			default: printf("unknown\n");
		}
		close(fd);
		return 0;
	}

	// read the drive status info
	status = ioctl(fd, CDROM_DRIVE_STATUS, CDSL_CURRENT);
	//printf("%d\n", status);
	switch(status) {
		case -1:
		case CDS_NO_DISC:
			close(fd);
			if (!opts.quiet) printf("no disc!\n");
			return DISC_TYPE_NODISC;
			break;
		case CDS_TRAY_OPEN:
			close(fd);
			if (!opts.quiet) printf("tray open!\n");
			return DISC_TYPE_NODISC;
			break;
		case CDS_DRIVE_NOT_READY:
			close(fd);
			if (!opts.quiet) printf("drive not ready!\n");
			return DISC_TYPE_NODISC;
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
				return DISC_TYPE_NODISC;
			} else {
				err_exit("getstatus", DISC_TYPE_NODISC);
			}
	}

	if (drive_type != DRIVE_TYPE_CDROM && drive_type != DRIVE_TYPE_CDBURNER) {
		dvd_struct dvd;
		memset(&dvd, 0, sizeof(dvd));
		dvd.type = DVD_STRUCT_MANUFACT;
		if (ioctl(fd, DVD_READ_STRUCT, &dvd) >= 0) {
			/*
			printf("%d,%d,%d,%d, %d,%d,%s, %d,%d, %d,%d,%d,%d, %d,%d,%s\n",
			dvd.copyright.type, dvd.copyright.layer_num, dvd.copyright.cpst, dvd.copyright.rmi,
			dvd.bca.type, dvd.bca.len, dvd.bca.value,
			dvd.physical.type, dvd.physical.layer_num,
			dvd.manufact.type, dvd.manufact.layer_num, dvd.manufact.len, dvd.manufact.value,
			dvd.disckey.type, dvd.disckey.agid, dvd.disckey.value);
			*/
			disc_type = DISC_TYPE_DVD;
		} else {
			//perror("DVD_READ_STRUCT");
		}
	}

	struct cdrom_tochdr th;
	status = ioctl(fd, CDROMREADTOCHDR, &th);
	if (status != 0) {
		close(fd);
		if (!opts.quiet) printf("blank or damaged disc\n");
		int ret = DISC_TYPE_CD_BLANK;
		if (disc_type == DISC_TYPE_DVD) {
			ret = DISC_TYPE_DVD_BLANK;
		}
		err_exit("gettochdr", ret);
	}

	//====================================================

	if (!opts.quiet) printf("cdtype: ");

	if (disc_type == DISC_TYPE_DVD) {
		close(fd);
		if (!opts.quiet) printf("dvd\n");
		return DISC_TYPE_DVD;
	}

	status = ioctl(fd, CDROM_DISC_STATUS, CDSL_CURRENT);
	close(fd);
	switch (status) {
		case CDS_AUDIO:
			if (!opts.quiet) printf("audio\n");
			return DISC_TYPE_CD_AUDIO;
			break;
		case CDS_DATA_1:
			if (!opts.quiet) printf("data mode 1\n");
			return DISC_TYPE_DATA;
			break;
		case CDS_DATA_2:
			if (!opts.quiet) printf("data mode 2\n");
			return DISC_TYPE_DATA;
			break;
		case CDS_MIXED:
			if (!opts.quiet) printf("mixed mode\n");
			return DISC_TYPE_CD_MIXED;
			break;
		case CDS_XA_2_1:
			if (!opts.quiet) printf("xa\n");
			return DISC_TYPE_DATA;
			break;
		case CDS_XA_2_2:
			if (!opts.quiet) printf("cdi\n");
			return DISC_TYPE_DATA;
			break;
		default:
			if (!opts.quiet) printf("unknown\n");
			return DISC_TYPE_UNKNOWN;
			break;
	}
}
