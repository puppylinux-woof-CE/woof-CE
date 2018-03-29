/*
 * big parts taken from cdfs (C) 1999, 2000, 2001 by Michiel Ronsse
 * relesed under the GPL v.2
 * more parts taken from isoinfo/isodump (W) 1993 Eric Youngdale,
 * (C) 1993 Yggdrasil Computing, Incorporated, also released
 * under the GPL v.2
 */

#ifndef lint
static char vcid[] = "$Id: cddetect.c,v 2.2 2008/06/17 14:30:06 bodo Exp $";
#endif

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <limits.h>
#include <linux/cdrom.h>
#include <linux/iso_fs.h>


#define CDDEVICE "/dev/cdrom"

// exitcodes for CD/DVD types

#define TYPE_UNKNOWN	-1
#define TYPE_AUDIO	1
#define TYPE_DATA	2
#define TYPE_ISO	3
#define TYPE_DVD	4
#define TYPE_VIDEODVD	5
#define TYPE_VCD	6
#define TYPE_SVCD	7
#define TYPE_UVCD	8
#define TYPE_MIXED	50

/* TODO
 *
 * - find an test some MODE0 CDs
 * - find an test some MODE2 CDs without (or with invalid) subheader
 * - include support for CD-i (MODE21)
 * - what is the difference between MODE21 and MODE22?
 * - what is MODE0?
 * - which modes do exist?
 * * cdromreadraw: Invalid argument on DVDs
 *   (circumvented)
 * * cdromreadraw on DVDs in DVD-Writers works - bummer
 *   (circumvented?)
 */

static struct {
	unsigned int verbose;
	unsigned int quiet;
	unsigned char device[255];
} opts = { 0, 0, CDDEVICE };

#if 0
void dump(const char *buf, int start, int offset, int len)
{
  int i,j;
  int size = len - start;

  printf("data:\n");
  for (j=0; j < (size / 16); j++) {
    printf("%.4x: ", j*16+offset);
    for (i=0; i < 16; i++)
      printf("%.2x ", buf[j*16+i]);
    printf("  ");
    for (i=0; i < 16; i++)
      printf("%c", ((buf[j*16+i] >= ' ') && (buf[j*16+i] <= '~')) ? buf[j*16+i] : '.');
    printf("\n");
  }
  if ((size % 16) != 0) {
    printf("%.4x: ", j*16+offset);
    for (i=0; i < (size % 16); i++)
      printf("%.2x ", buf[j*16+i]);
    printf("           ");
    for (i=0; i < (size % 16); i++)
      printf("%c", ((buf[j*16+i] >= ' ') && (buf[j*16+i] <= '~')) ? buf[j*16+i] : '.');
    printf("\n");
  }
}
#endif

static char temp_buffer[4096];

static char *remove_trailing_blanks( char *string_p, int bytes) {
	char *temp_p;

	/*
	 *  Make copy of string in temporary buffer
	 *  Get address of last character in string
	 */

	(void) memcpy(temp_buffer, string_p, bytes);
	temp_p = temp_buffer + bytes - 1;

	/*
	 *  While string not exhausted and current character is a blank
	 *      Move one character to the left in the string
	 */

	while ((temp_p >= temp_buffer) && (*temp_p == ' ')) {
		temp_p -= 1;
	}

	/*
	 *  We went too far left, move one character back to right
	 *  Insert null character to terminate string
	 */

	temp_p += 1;
	*temp_p = '\0';
	return &temp_buffer[0];
}

int isonum_733(char *p)
{
	return ((p[0] & 0xff)
			| ((p[1] & 0xff) << 8)
			| ((p[2] & 0xff) << 16)
			| ((p[3] & 0xff) << 24));
}

void lba2msf(unsigned int lba, struct cdrom_msf *msf) {
	msf->cdmsf_min0   = (lba + CD_MSF_OFFSET) / CD_FRAMES / CD_SECS;
	msf->cdmsf_sec0   = (lba + CD_MSF_OFFSET) / CD_FRAMES % CD_SECS;
	msf->cdmsf_frame0 = (lba + CD_MSF_OFFSET) % CD_FRAMES;
}

void err_exit(const char *message) {
	if (!opts.quiet)
		perror(message);
	exit(-1);
}

int print_iso_info(struct iso_primary_descriptor *iso_info)
{
	struct iso_directory_record *iso_dir = (struct iso_directory_record *)iso_info->root_directory_record;

	if (opts.verbose) {
		printf("\ttype: %c info: %.5s version: %c\n"
				"\tdate: %.2s/%.2s/%.4s time: %.2s:%.2s:%.2s\n"
				"\tsystem: %.32s\n\tvolume: %.32s\n",
				iso_info->type[0] + 48,
				iso_info->id,
				iso_info->version[0] + 48,
				iso_info->creation_date + 6,
				iso_info->creation_date + 4,
				iso_info->creation_date,
				iso_info->creation_date + 8,
				iso_info->creation_date + 10,
				iso_info->creation_date + 12,
				iso_info->system_id,
				iso_info->volume_id);
		printf("\tpublisher: %.128s\n",
				remove_trailing_blanks(iso_info->publisher_id, 128));
		printf("\tpreparer: %.128s\n",
				remove_trailing_blanks(iso_info->preparer_id, 128));
		printf("\tapplication: %.128s\n",
				remove_trailing_blanks(iso_info->application_id, 128));
		printf("\troot-extent: %d,"
				"extent-size: %d\n",
				isonum_733(iso_dir->extent),
				isonum_733(iso_dir->size));
	}
	return isonum_733(iso_dir->extent);
}

int process_iso_extent(unsigned char *frame, unsigned int offset) {

	struct iso_directory_record *iso_dir;
	char name_buf[256];
	int retval = 0;

	while (1 == 1) {
		iso_dir = (struct iso_directory_record *) &frame[offset];
		if (iso_dir->length[0] == 0) break;
		name_buf[0] = 0;
		if (iso_dir->name_len[0] == 1 && iso_dir->name[0] == 0)
			strcpy(name_buf, ".");
		else if (iso_dir->name_len[0] == 1 && iso_dir->name[0] == 1)
			strcpy(name_buf, "..");
		else {
			strncpy(name_buf, iso_dir->name, iso_dir->name_len[0]);
			name_buf[iso_dir->name_len[0]] = 0;
		}
		if (opts.verbose)
			printf("\t\t%s\n", name_buf);
		if (iso_dir->flags[0] & 2) { // dir
			if (!strncasecmp(name_buf, "video_ts", iso_dir->name_len[0])) {
				retval = 1;
				if (!opts.quiet)
					printf("Video-DVD detected\n");
			}
		}
		offset += frame[offset];
		if (offset > 2048 - offsetof(struct iso_directory_record, name[0])) break;
	}
	return retval;
}

int process_track(const int fd, const unsigned int track,
		const unsigned int firsttrack, const unsigned int lasttrack) {

	int status;
	struct cdrom_tocentry te;
	struct cdrom_msf *msf;
	unsigned char frame[2500];
	unsigned int xa_data_offset = 0;  // shut up gcc
	char videocd_type[9];
	char videocd_title[17];
	unsigned int offset;
	unsigned int isooffset;
	struct iso_primary_descriptor iso_info;
	int extent;
	int readmode;
	FILE *infile;
	int tracktype = TYPE_UNKNOWN;

	te.cdte_track = track;
	te.cdte_format= CDROM_MSF;
	status = ioctl(fd, CDROMREADTOCENTRY, &te);
	if (status != 0)
		err_exit("gettoc");
	if (!opts.quiet) {
		if (track == CDROM_LEADOUT)
			printf("leadout: ");
		else
			printf("%7d: ", track);
		printf("adr:%d, ctrl:%d, format:%d, %02d:%02d:%02d (%8d), datamode:%d ",
				te.cdte_adr, te.cdte_ctrl, te.cdte_format,
				te.cdte_addr.msf.minute,
				te.cdte_addr.msf.second,
				te.cdte_addr.msf.frame,
				te.cdte_addr.msf.frame + (te.cdte_addr.msf.minute * 60 + te.cdte_addr.msf.second) * CD_FRAMES,
				te.cdte_datamode);
	}
	if (te.cdte_ctrl & CDROM_DATA_TRACK) {
		tracktype = TYPE_DATA;
		// as of kernel 2.6.6, cdte_format isn't set >_<
		if (!opts.quiet) {
			if (te.cdte_format == 0x10)
				printf("[cdi]");
			else if (te.cdte_format == 0x20)
				printf("[xa]");
			else printf("[data]");
		}
		if (track == CDROM_LEADOUT) {
			// LEADOUT
			if (!opts.quiet)
				printf("\n");
			return 0;
		}
		// check mode of data track and possibly submodes
		msf = (struct cdrom_msf*) frame;
		msf->cdmsf_min0 = te.cdte_addr.msf.minute;
		msf->cdmsf_sec0 = te.cdte_addr.msf.second;
		msf->cdmsf_frame0 = te.cdte_addr.msf.frame + 16;
		status = ioctl(fd, CDROMREADRAW, (unsigned long)msf);
		if (status != 0) {
			// may be a DVD
			if (errno == EINVAL &&
					firsttrack == 1 &&
					lasttrack  == 1 &&
					te.cdte_addr.msf.minute == 0 &&
					te.cdte_addr.msf.second == 2 &&
					te.cdte_addr.msf.frame  == 0) {
				// there is only one data track
				// and it starts at the beginning
				// of the disc.
				// as CDROMREADRAW failed, this
				// is very likely a DVD
				infile = fdopen(fd, "rb");
				if (infile == NULL) {
					perror("fdopen");
					return -1;
				}
				lseek(fileno(infile), ((off_t)(16)) <<11, SEEK_SET);
				read(fileno(infile), &iso_info, sizeof (iso_info));
				if (iso_info.type[0] == ISO_VD_PRIMARY &&
						strncmp(iso_info.id, ISO_STANDARD_ID, sizeof(iso_info.id)) == 0 &&
						iso_info.version[0] == 1) {
					// this _is_ ISO9660
					tracktype = TYPE_DVD;
					if (!opts.quiet)
						printf(" [iso]\n");
					extent = print_iso_info(&iso_info);

					lseek(fd, ((off_t)extent) << 11, SEEK_SET);
					read(fd, frame, sizeof(frame));

					if (process_iso_extent(frame, 0))
						tracktype = TYPE_VIDEODVD;
				} else {
					perror("ISO");
					return -1;
				}
				return tracktype;
			} else {
				perror("cdromreadraw");
				return -1;
			}
		}
		// dump(frame, 0, 0, sizeof(frame));
		if (frame[15] == 0x01) { // MODE1
			if (!opts.quiet)
				printf(" [MODE1]");
			offset = 16;
			readmode = CDROMREADMODE1;
			isooffset = 0;
		} else if (frame[15] == 0x02) { // MODE2 subheader
			if (frame[15+1+0] == frame[15+1+4] &&
					frame[15+1+1] == frame[15+1+5] &&
					frame[15+1+2] == frame[15+1+6] &&
					frame[15+1+3] == frame[15+1+7]) {
				if ((frame[15+1+2] & 0x20) != 0) {
					// MODE2_FORM2
					if (!opts.quiet)
						printf(" [MODE22]");
				} else {
					// MODE2_FORM1
					if (!opts.quiet)
						printf(" [MODE21]");
				}
				offset = 24;
				if (frame[15+1+2] != 0 &&
						frame[15+1+0] < 8 &&
						frame[15+1+1] < 8) {
					xa_data_offset = 8;
				} else {
					xa_data_offset = 0;
				}
			} else { // illegal subheader, assume MODE2
				if (!opts.quiet)
					printf(" [MODE2]");
				offset = 16;  // FIXME
			}
			readmode = CDROMREADMODE2;
			isooffset = 0x68;
		} else { // invalid mode, assume MODE0
			if (!opts.quiet)
				printf(" [MODE0]");
			/* offset used to be 16 as I didn't see a MODE0 CD
			 * yet. As it turns out, some or even all DVD-Writers
			 * support CDROMREADRAW even on DVDs (in contrast to
			 * DVD-ROMs) so the return code of CDROMREADRAW can
			 * not be used to distinguish between CDs and DVDs.
			 *
			 * The DVD-Writer I used returned the ISO9660
			 * primary descriptor on offset 0 of the data
			 * returned by CDROMREADRAW, so setting offset to 0
			 * here ist a workaround.
			 * As the ISO9660 primary descriptor stores (part
			 * of) the system_id at offset 15, and system_id is
			 * defined to be achars, there shouldn't be the
			 * possibility to mis-detect such DVDs as MODE1 or
			 * MODE2.
			 */
			offset = 0;  // FIXME
			readmode = CDROMREADMODE1;
			isooffset = 0;
		}

		if (!strncmp(&frame[1+offset], "CD001", 5)) {
			if (!opts.quiet)
				printf(" [iso]\n");
			tracktype = TYPE_ISO;
			memcpy(&iso_info, &frame[offset], sizeof(struct iso_primary_descriptor));
			extent = print_iso_info(&iso_info);

			msf = (struct cdrom_msf*) frame;
			lba2msf(extent, msf);
			status = ioctl(fd, readmode, (unsigned long)msf);
			if (status != 0) {
				perror("cdromreadmodeX");
				return -1;
			}

			if (process_iso_extent(frame, isooffset))
				tracktype = TYPE_VIDEODVD;
		} else {  // assume (S)VCD
			msf = (struct cdrom_msf*) frame;
			msf->cdmsf_min0 = 0;
			msf->cdmsf_sec0 = 4;
			msf->cdmsf_frame0 = 0;
			status = ioctl(fd, CDROMREADMODE2, (unsigned long)msf);
			if (status != 0) {
				perror("cdromreadmode2");
				return -1;
			}

			strncpy(videocd_type, frame+xa_data_offset, 8);
			videocd_type[8] = 0;
			strncpy(videocd_title, frame+xa_data_offset+10, 16);
			videocd_title[16]=0;
			printf(" [VCD: %s, %s]\n", videocd_type, videocd_title);
			if (!strncmp(videocd_type, "VIDEO_CD", sizeof(videocd_type)))
				tracktype = TYPE_VCD;
			else if (!strncmp(videocd_type, "SUPERVCD", sizeof(videocd_type)))
				tracktype = TYPE_SVCD;
			else
				tracktype = TYPE_UVCD;
		}


	} else {
		tracktype = TYPE_AUDIO;
		if (!opts.quiet)
			printf ("[audio]\n");
	}
	return tracktype;
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
	fprintf(stderr, "\t- ISO\t\t%3d\n", TYPE_ISO);
	fprintf(stderr, "\t- dvd\t\t%3d\n", TYPE_DVD);
	fprintf(stderr, "\t- VideoDVD\t%3d\n", TYPE_VIDEODVD);
	fprintf(stderr, "\t- VCD\t\t%3d\n", TYPE_VCD);
	fprintf(stderr, "\t- SVCD\t\t%3d\n", TYPE_SVCD);
	fprintf(stderr, "\t- UVCD\t\t%3d\n", TYPE_UVCD);
	fprintf(stderr, "\t- mixed\t\t%3d\n", TYPE_MIXED);
	exit(0);
}


int main(int argc, char *const *argv)
{
	int fd;
	int status;
	struct cdrom_tochdr th;
	int track;
	int optchar;
	int tracktype;
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
	if (optind < argc)
		usage(argv[0]);

	if (opts.verbose > 0 && opts.quiet > 0)
		usage(argv[0]);

	fd = open(opts.device, O_RDONLY | O_NONBLOCK);
	if (fd < 0)
		err_exit("open");

	// read the drive status info
	status = ioctl(fd, CDROM_DRIVE_STATUS, CDSL_CURRENT);

	// CDS_NO_INFO: function not implemented
	// CDS_NO_DISC: no disc
	// CDS_TRAY_OPEN: tray open
	// CDS_DRIVE_NOT_READY: drive not ready
	// CDS_DISC_OK: disk OK

	switch(status) {
		case CDS_NO_DISC:
			close(fd);
			printf("no disc!\n");
			return -1;
			break;
		case CDS_TRAY_OPEN:
			close(fd);
			printf("tray open!\n");
			return -1;
			break;
		case CDS_DRIVE_NOT_READY:
			close(fd);
			printf("drive not ready!\n");
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

	if (!opts.quiet)
		printf("start track: %d, end track %d\n", th.cdth_trk0, th.cdth_trk1);

	for (track = th.cdth_trk0; track <= th.cdth_trk1; track++) {
		tracktype = process_track(fd, track, th.cdth_trk0, th.cdth_trk1);
		if (tracktype > 0) {
			if (cdtype == 0) {
				cdtype = tracktype;
			} else {
				if (cdtype != tracktype) {
					if (cdtype == TYPE_ISO &&
					    (tracktype == TYPE_VCD ||
					     tracktype == TYPE_SVCD ||
					     tracktype == TYPE_UVCD))
						cdtype = tracktype;
					else
						cdtype = TYPE_MIXED;
				}
			}
		}
	}
	(void) process_track(fd, CDROM_LEADOUT, th.cdth_trk0, th.cdth_trk1);

	status = ioctl(fd, CDROM_DISC_STATUS, CDSL_CURRENT);

	close(fd);

	if (!opts.quiet) {
		printf("cdtype: ");

		switch (status) {
			case CDS_AUDIO: printf("audio\n"); break;
			case CDS_DATA_1: printf("data mode 1\n"); break;
			case CDS_DATA_2: printf("data mode 2\n"); break;
			case CDS_MIXED: printf("mixed mode\n"); break;
			case CDS_XA_2_1: printf("xa\n"); break;
			case CDS_XA_2_2: printf("cdi\n"); break;
			case CDS_NO_INFO: printf("NO INFO\n"); break;
			case CDS_NO_DISC: printf ("NO DISC\n"); break;
			default: printf("unknown\n"); break;
		}
	}
	return cdtype;
}
