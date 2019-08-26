/*
*
* path:
*	/usr/local/pup_event/pup_event_frontend_d
*
* compile:
*	gcc -o pup_event_frontend_d pup_event_frontend_d.c
*	strip pup_event_frontend_d
*
*/

#include <stdlib.h>        // getenv(), system()
#include <sys/types.h>
#include <unistd.h>        // getpid() access()
#include <string.h>        // strstr() etc..
#include <stdio.h>
#include <dirent.h>        // opendir(), readdir()

#include <mntent.h>        //mntent
// disc_is_inserted()
#include <sys/ioctl.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/cdrom.h>

int debug = 0;
char *app_name = NULL;
FILE *outf = NULL;
int PUPMODE = 5;

#define trace(...) { fprintf (outf, __VA_ARGS__); }

//=============================================================================

int dev_is_mounted(const char *dev) {
	struct mntent *ent;
	FILE *fhandle;
	fhandle = setmntent("/proc/mounts", "r");
	if (fhandle == NULL) {
		return 0; /* error */
	}
	while (NULL != (ent = getmntent(fhandle))) {
		//                    /dev/sda2       /mnt/sda2
		//printf("%s %s\n", ent->mnt_fsname, ent->mnt_dir);
		if (strcmp(ent->mnt_fsname, dev) == 0) {
			endmntent(fhandle);
			return 1; /* ok */
		}
	}
	endmntent(fhandle);
	return 0; /* error */
}

int disc_is_inserted(char *device) { /* /dev/sr0 */
	int fd, status;
	fd = open(device, O_RDONLY | O_NONBLOCK);
	if (fd < 0) {
		return 0; /* err */
	}
	// read the drive status info
	status = ioctl(fd, CDROM_DRIVE_STATUS, CDSL_CURRENT);
	close(fd);
	if (status == CDS_DISC_OK) {
		return 1; /* ok */
	}
	return 0; /* err */
}

//=======================================================================
//                  FRONTEND_TIMEOUT
//=======================================================================

int MINUTE=0;
int CHECK_SR0=1; // check sr0

void frontend_timeout(void) {
	/* check if lock files are active */
	if (access("/tmp/frontend_startup_lock", F_OK) != -1) {
		return;
	}
	struct dirent *pDirent;
	DIR *pDir;
	pDir = opendir("/tmp");
	if (pDir) {
		while ((pDirent = readdir(pDir)) != NULL) {
			//printf ("[%s]\n", pDirent->d_name);
			if (strstr(pDirent->d_name, "frontend_change_processing_")) {
				closedir (pDir);
				return;
			}
		}
		closedir (pDir);
	}
	//
	MINUTE += 10;
	if (MINUTE == 60) {
		MINUTE=0;
		//-
		int ret = system("/usr/local/pup_event/pup_event_timeout60");
		if (ret == 0) {
			CHECK_SR0=1; // do check
		} else {
			CHECK_SR0=0; // don't check
		}
	}
	if (!CHECK_SR0) {
		return;
	}
	// probe optical drives
	char *drvname = NULL;
	char blockdev[30] = "";
	for (int i = 0; ; i++) {
		snprintf(blockdev, sizeof(blockdev), "/dev/sr%d", i);
		drvname = strrchr(blockdev, '/');
		if (drvname) drvname++;
		if (access(blockdev, F_OK) == -1) {
			break;
		}
		if (dev_is_mounted(blockdev)) {
			if (debug) trace("%s is mounted\n", blockdev);
			continue;
		}
		char pup_event_drv[50];
		char drv_uevent[40];
		snprintf(drv_uevent, sizeof(drv_uevent), "/sys/block/%s/uevent", drvname);
		snprintf(pup_event_drv, sizeof(pup_event_drv), "/tmp/pup_event_frontend/drive_%s", drvname);
		if (debug) trace("%s - %s\n", drv_uevent, pup_event_drv);
		FILE *fp = fopen(drv_uevent, "w");
		if (fp) {
			if (disc_is_inserted(blockdev)) {
				if (debug) trace("disc is inserted\n");
				if (access(pup_event_drv, F_OK) == -1) {
					if (debug) trace("add\n");
					fprintf(fp, "add\n"); // echo "add" > /sys/block/${DRV_NAME}/uevent
				}
			} else {
				if (debug) trace("disc is NOT inseted\n");
				if (access(pup_event_drv, F_OK) != -1) {
					if (debug) trace("remove\n");
					fprintf(fp, "remove\n"); // echo "remove" > /sys/block/${DRV_NAME}/uevent
				}
			}
			fclose(fp);
		}
	}
	//
	return;
}

//=======================================================================
//                        MAIN
//=======================================================================


int main(int argc, char **argv) {

	outf = stderr;

	app_name = strrchr(argv[0], '/');
	if (app_name) app_name++;
	if (argv[1]) {
		if (strcmp(argv[1], "-debug") == 0) debug = 1;
	}
	if (getenv("PUPEVENT_DEBUG"))    debug = 1;
	if (getenv("PUP_EVENT_DEBUG"))   debug = 1;

	fprintf(stderr, "%s: starting...\n", app_name);

	// ==
	int ret = system("/usr/local/pup_event/frontend_startup");
	if (ret != 0) {
		trace("%s: exited with code: %d\n", app_name, WEXITSTATUS(ret));
		trace("exiting...\n");
		return 9;
	}

	// ==
	ret = system("/usr/local/bin/pupmode");
	PUPMODE = WEXITSTATUS(ret);
	if (debug) trace("PUPMODE %d\n", PUPMODE);

	unlink("/tmp/services/pup_event_timeout");

	while (1) {
		sleep(10);
		frontend_timeout();
	}

	return 0;
}

/* EOF */
