#ifdef HAVE_LANDLOCK
#	include <linux/landlock.h>
#	include <syscall.h>
#endif
#include <fcntl.h>
#include <unistd.h>
#include <sys/prctl.h>
#include <dirent.h>
#include <errno.h>
#include <string.h>
#include <sched.h>
#include <sys/types.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef HAVE_LANDLOCK

#	ifndef LANDLOCK_ACCESS_FS_REFER
#		define LANDLOCK_ACCESS_FS_REFER 0
#	endif

static inline
long landlock_create_ruleset(const struct landlock_ruleset_attr *const attr, const size_t size, const __u32 flags)
{
	return syscall(__NR_landlock_create_ruleset, attr, size, flags);
}

static inline
long landlock_add_rule(const int ruleset_fd, const enum landlock_rule_type rule_type, const void *const rule_attr, const __u32 flags)
{
	return syscall(__NR_landlock_add_rule, ruleset_fd, rule_type, rule_attr, flags);
}

static inline
long landlock_restrict_self(const int ruleset_fd, const __u32 flags)
{
	return syscall(__NR_landlock_restrict_self, ruleset_fd, flags);
}

static
int add_rule(const int ruleset_fd, const int rootfd, const char *path, struct landlock_path_beneath_attr *attr)
{
	int err;
	attr->parent_fd = openat(rootfd, path, O_PATH);
	if (attr->parent_fd < 0) return -1;
	err = landlock_add_rule(ruleset_fd, LANDLOCK_RULE_PATH_BENEATH, attr, 0);
	close(attr->parent_fd);
	return err;
}

#endif

int main(int argc, char *argv[])
{
#ifdef HAVE_LANDLOCK
	static const char *rw_dirs[] = {
		"home/spot",
		"dev",
		"proc",
		"tmp",
		"mnt",
	};
	static const char *skip_dirs[] = {
		".",
		"..",
		"root",
		"home",
		"dev",
		"proc",
		"tmp",
		"mnt",
	};
	struct landlock_ruleset_attr ruleset_attr = {
		.handled_access_fs =
			LANDLOCK_ACCESS_FS_EXECUTE |
			LANDLOCK_ACCESS_FS_WRITE_FILE |
			LANDLOCK_ACCESS_FS_READ_FILE |
			LANDLOCK_ACCESS_FS_READ_DIR |
			LANDLOCK_ACCESS_FS_REMOVE_DIR |
			LANDLOCK_ACCESS_FS_REMOVE_FILE |
			LANDLOCK_ACCESS_FS_MAKE_CHAR |
			LANDLOCK_ACCESS_FS_MAKE_DIR |
			LANDLOCK_ACCESS_FS_MAKE_REG |
			LANDLOCK_ACCESS_FS_MAKE_SOCK |
			LANDLOCK_ACCESS_FS_MAKE_FIFO |
			LANDLOCK_ACCESS_FS_MAKE_BLOCK |
			LANDLOCK_ACCESS_FS_MAKE_SYM |
			LANDLOCK_ACCESS_FS_REFER
	};
	struct landlock_path_beneath_attr ro_attr = {
		.allowed_access =
			LANDLOCK_ACCESS_FS_EXECUTE |
			LANDLOCK_ACCESS_FS_READ_FILE |
			LANDLOCK_ACCESS_FS_READ_DIR
	};
	struct landlock_path_beneath_attr rw_attr = {
		.allowed_access =
			LANDLOCK_ACCESS_FS_EXECUTE |
			LANDLOCK_ACCESS_FS_WRITE_FILE |
			LANDLOCK_ACCESS_FS_READ_FILE |
			LANDLOCK_ACCESS_FS_READ_DIR |
			LANDLOCK_ACCESS_FS_REMOVE_DIR |
			LANDLOCK_ACCESS_FS_REMOVE_FILE |
			LANDLOCK_ACCESS_FS_MAKE_CHAR |
			LANDLOCK_ACCESS_FS_MAKE_DIR |
			LANDLOCK_ACCESS_FS_MAKE_REG |
			LANDLOCK_ACCESS_FS_MAKE_SOCK |
			LANDLOCK_ACCESS_FS_MAKE_FIFO |
			LANDLOCK_ACCESS_FS_MAKE_BLOCK |
			LANDLOCK_ACCESS_FS_MAKE_SYM |
			LANDLOCK_ACCESS_FS_REFER
	};
	DIR *dir = NULL;
	struct dirent *ent;
	int i, root_fd = -1, ruleset_fd = -1;
#endif
	struct passwd *spot;
	FILE *fp;
	int out;

	if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) < 0) goto exec;

#ifdef HAVE_LANDLOCK
#	if LANDLOCK_ACCESS_FS_REFER != 0
	if (landlock_create_ruleset(NULL, 0, LANDLOCK_CREATE_RULESET_VERSION) < 2) {
		ruleset_attr.handled_access_fs &= ~LANDLOCK_ACCESS_FS_REFER;
		rw_attr.allowed_access &= ~LANDLOCK_ACCESS_FS_REFER;
	}
#	endif

	if ((ruleset_fd = landlock_create_ruleset(&ruleset_attr, sizeof(ruleset_attr), 0)) < 0) goto exec;
	if ((root_fd = open("/", O_DIRECTORY)) < 0) goto exec;
	if (!(dir = fdopendir(root_fd))) goto exec;

	while (1) {
next:
		errno = 0;
		if (!(ent = readdir(dir))) {
			if (errno) goto exec;
			break;
		}

		if (ent->d_type != DT_DIR) continue;

		for (i = 0; i < sizeof(skip_dirs) / sizeof(skip_dirs[0]); ++i) {
			if (strcmp(ent->d_name, skip_dirs[i]) == 0) goto next;
		}

		if (add_rule(ruleset_fd, root_fd, ent->d_name, &ro_attr) < 0) goto exec;
	}

	for (i = 0; i < sizeof(rw_dirs) / sizeof(rw_dirs[0]); ++i) {
		if (add_rule(ruleset_fd, root_fd, rw_dirs[i], &rw_attr) < 0) goto exec;
	}

	landlock_restrict_self(ruleset_fd, 0);
#endif

exec:
	if (unshare(CLONE_NEWUSER) < 0 || !(spot = getpwnam("spot"))) goto cleanup;

	if (!(fp = fopen("/proc/self/uid_map", "w"))) goto cleanup;
	out = fprintf(fp, "%d %d 1", spot->pw_uid, spot->pw_uid);
	fclose(fp);
	if (out <= 0) goto cleanup;

	if (!(fp = fopen("/proc/self/setgroups", "w"))) goto cleanup;
	out = fwrite("deny", 1,  4, fp);
	fclose(fp);
	if (out != 4) goto cleanup;

	if (!(fp = fopen("/proc/self/gid_map", "w"))) goto cleanup;
	fprintf(fp, "%d %d 1", spot->pw_gid, spot->pw_gid);
	fclose(fp);

cleanup:
#ifdef HAVE_LANDLOCK
	if (dir) closedir(dir);
	else if (root_fd != -1) close(root_fd);
	if (ruleset_fd != -1) close(ruleset_fd);
#endif

	execvp(argv[1], &argv[1]);
	return EXIT_FAILURE;
}
