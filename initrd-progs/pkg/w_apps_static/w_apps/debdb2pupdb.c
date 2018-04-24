/*
 * this is an efficient C replacement for the extremely slow debdb2pupdb.bac -
 * should be about 75 times faster according to my non-scientific benchmarks.
 * this implementation uses heavily buffered I/O, hashing, very little memory
 * management, compiled REs and other tricks to achieve this amazing
 * performance.
 *
 * to build:
 * musl-gcc -static -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o debdb2pupdb debdb2pupdb.c
 * strip --strip-all -R .note -R .comment debdb2pupdb
 *
 * cheers,
 * iguleder, September 2015
 *
 * location: woof-arch/<arch>/build/support/debdb2pupdb
 */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <regex.h>
#include <ctype.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define BUF_SIZE (1024 * 1024)
#define MAX_PKGS (60000)
#define VAL_SIZE (16 * 1024)
#define REV_SIZE (32)

static void trim_ver(char *ver, regex_t *preg, char **outver, char *rev)
{
	regmatch_t pmatch;
	char *pos, *sep;
	/* strip "1:" from "1:2.0.10-1ubuntu3" */
	sep = strchr(ver, ':');
	if (sep == NULL) *outver = ver;
	else {
		for (pos = ver; sep > pos; ++pos) if (isdigit(pos[0]) == 0) return;
		*outver = sep + 1;
	}
	/* kick "~2011week36" in "2.2~2011week36" */
	sep = strchr(*outver, '~');
	if (sep != NULL) sep[0] = '\0';

	/* kick "-1ubuntu3" from "1:2.0.10-1ubuntu3" */
	if (regexec(preg, *outver, 1, &pmatch, 0) == REG_NOMATCH) {
		if (rev != NULL) rev[0] = '\0';
	} else {
		(*outver + pmatch.rm_so)[0] = '\0';
		if (rev != NULL) memcpy(rev, *outver + pmatch.rm_so + 1, pmatch.rm_eo - pmatch.rm_so);
	}
}

enum fields {
	FIELD_DESC = 0,
	FIELD_PATH,
	FIELD_NAME,
	FIELD_SIZE,
	FIELD_ARCH,
	FIELD_VER,
	FIELD_DEPS,
	FIELD_WWW,
	FIELD_SECT,
	FIELD_MAX
};

static const char *fields_str[] = {
	"Description",
	"Filename",
	"Package",
	"InstalledSize",
	"Architecture",
	"Version",
	"Depends",
	"Homepage",
	"Section"
};

// =======================================================

static const unsigned long crc32_table[256] = {
	0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F,
	0xE963A535, 0x9E6495A3, 0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
	0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91, 0x1DB71064, 0x6AB020F2,
	0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
	0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9,
	0xFA0F3D63, 0x8D080DF5, 0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172,
	0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B, 0x35B5A8FA, 0x42B2986C,
	0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
	0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423,
	0xCFBA9599, 0xB8BDA50F, 0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
	0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D, 0x76DC4190, 0x01DB7106,
	0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
	0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D,
	0x91646C97, 0xE6635C01, 0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
	0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457, 0x65B0D9C6, 0x12B7E950,
	0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
	0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7,
	0xA4D1C46D, 0xD3D6F4FB, 0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
	0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9, 0x5005713C, 0x270241AA,
	0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
	0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81,
	0xB7BD5C3B, 0xC0BA6CAD, 0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
	0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683, 0xE3630B12, 0x94643B84,
	0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
	0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB,
	0x196C3671, 0x6E6B06E7, 0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
	0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5, 0xD6D6A3E8, 0xA1D1937E,
	0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
	0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55,
	0x316E8EEF, 0x4669BE79, 0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236,
	0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F, 0xC5BA3BBE, 0xB2BD0B28,
	0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
	0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F,
	0x72076785, 0x05005713, 0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38,
	0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21, 0x86D3D2D4, 0xF1D4E242,
	0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
	0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69,
	0x616BFFD3, 0x166CCF45, 0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2,
	0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB, 0xAED16A4A, 0xD9D65ADC,
	0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
	0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693,
	0x54DE5729, 0x23D967BF, 0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
	0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D
};

/* based on CRC-32 version 2.0.0 by Craig Bruce, 2006-04-29, public domain -
 * http://csbruce.com/software/crc32.c */
static unsigned long crc32(const unsigned long in,
                           const unsigned char *buf,
                           const size_t len)
{
	size_t i; unsigned long crc32;
	crc32 = in ^ 0xFFFFFFFF;
	for (i = 0; len > i; ++i)
		crc32 = (crc32 >> 8) ^ crc32_table[(crc32 ^ buf[i]) & 0xFF];
	return crc32 ^ 0xFFFFFFFF;
}

static unsigned long *list_pkgs(const char *path,
                                const unsigned long initcrc,
                                char *buf,
                                int *out)
{
	unsigned long *pkgs;
	ssize_t len;
	int fd;
	char *curr, *next;

	pkgs = malloc(sizeof(unsigned long) * MAX_PKGS);
	*out = 0;

	fd = open(path, O_RDONLY);
	len = read(fd, buf, BUF_SIZE);
	close(fd);

	buf[len] = '\0';

	for (curr = buf; curr != NULL; ++*out) {
		next = strchr(curr + 1, ' ');
		if (next != NULL) next[0] = '\0';
		++curr;
		pkgs[*out] = crc32(initcrc, (unsigned char *) curr, strlen(curr));
		curr = next;
	}

	return pkgs;
}

// =======================================================

int main(int argc, char *argv[])
{
	regex_t preg;
	char rev[REV_SIZE];
	char *fields[FIELD_MAX];
	unsigned long initcrc, depcrc;
	char *buf, *inbuf, *outbuf, *sep, *fname, *pos, *ver, *name, *deprel, *depver, *line, *dep;
	FILE *db;
	unsigned long *pkgs, *baddeps;
	FILE *baddepf, *wwwf;
	int len, i, ndeps, npkgs, nbaddeps;

	/* Trisquel has some packages with the "ubuntu" suffix, so we have to search
	 * for both */
	regcomp(&preg, "(\\-|\\+)[0-9\\.]*(ubuntu|trisquel|debian|raspbian|build)[0-9\\.]*$", REG_EXTENDED);

	buf = malloc(BUF_SIZE);
	inbuf = malloc(BUF_SIZE);
	outbuf = malloc(BUF_SIZE);
	wwwf = fopen("/tmp/woof-homepages.acc", "w");
	db = fopen("/tmp/woof-debdb.in", "r");
	if (db == NULL) {
		perror("Error opening /tmp/woof-debdb.in");
		return(-1);
	}
	/* use a huge stdio buffer, to reduce the overhead of read() and write() -
	 * we want to spend time on output, not input */
	setvbuf(db, inbuf, BUF_SIZE, _IOFBF);
	setvbuf(stdout, outbuf, BUF_SIZE, _IOFBF);

	initcrc = crc32(0, NULL, 0);

	/* when running via woof-CE, read the list of all packages in the
	 * repository, hash their names for quick comparison, drop missing
	 * dependency packages and list them */
	if (access("/tmp/0setupcompletelistpkgs", F_OK) == 0) {
		baddeps = NULL;
		pkgs = list_pkgs("/tmp/0setupcompletelistpkgs", initcrc, buf, &npkgs);
		baddepf = fopen("/tmp/0setupnewinvaliddeps", "w");
		nbaddeps = 0;
	}
	else {
		/* when running via PPM, just drop the missing dependencies */
		baddeps = list_pkgs("/usr/local/petget/invaliddepslist", initcrc, buf, &nbaddeps);
		pkgs = NULL;
		baddepf = NULL;
		npkgs = 0;
	}

	/* allocate buffers for all fields; we set the first byte to \0 before each
	 * package so we can determine when a field is missing, without having to
	 * perform malloc() and free() every time */
	for (i = 0; i < FIELD_MAX; ++i) {
		fields[i] = malloc(VAL_SIZE);
		fields[i][0] = '\0';
	}

	/******************
	 **** BIG LOOP ****
	 ******************/

	do {

/* next */
next:
		line = fgets(buf, BUF_SIZE, db);
		if (line == NULL) {
			/* the last package entry does not end with a marker */
			if (feof(db) != 0) goto print;
			break;
		}

		len = strlen(buf);
		if (len == 0) continue;

		sep = strchr(buf, '|');
		if (sep == NULL) continue;
		sep[0] = '\0';

		/* extract all field values */
		for (i = 0; i < FIELD_MAX ; ++i) {
			if (strcmp(buf, fields_str[i]) == 0) {
				line[len - 1] = '\0';
				len -= 1 + (sep - buf);
				memcpy(fields[i], sep + 1, len);
				fields[i][len] = '\0';
				/* if a valid field was found, continue to the next line
				 * immediately */
				goto next;
			}
		}

		/* if the end of a package hasn't been reached yet, continue */
		if (strcmp(buf, "STARTMARKER") != 0) continue; //STARTMARKER

/* print */
print:
		/* make sure all mandatory fields are present */
		if (('\0' == fields[FIELD_DESC][0]) ||
		    ('\0' == fields[FIELD_PATH][0]) ||
		    ('\0' == fields[FIELD_NAME][0]) ||
		    ('\0' == fields[FIELD_ARCH][0]) ||
		    ('\0' == fields[FIELD_VER][0]) ||
		    ('\0' == fields[FIELD_SECT][0]))
			continue;

		/* skip debugging symbol packages */
		if (strstr(fields[FIELD_NAME], "-dbg") != NULL) goto cleanup;

		/* split the path into directory and file name */
		pos = strrchr(fields[FIELD_PATH], '/');
		pos[0] = '\0';
		++pos;
		fname = pos;

		/* trim the version */
		trim_ver(fields[FIELD_VER], &preg, &ver, rev);

		/* remove special charcaters from the description */
		for (i = strlen(fields[FIELD_DESC]) - 1; 0 <= i; --i) {
			if (strchr("'(),", fields[FIELD_DESC][i]) != NULL)
				for (pos = &fields[FIELD_DESC][i]; '\0' != pos[0]; ++pos) pos[0] = pos[1];
		}

		/* use the package name as specified in the sub-directory path, for find_cat */
		if (strlen(fields[FIELD_PATH]) == 0)
			name = fields[FIELD_NAME];
		else {
			name = strrchr(fields[FIELD_PATH], '/');
			++name;
		}

		fputs(fields[FIELD_NAME], stdout);
		putc('_', stdout);
		fputs(ver, stdout);
		putc('|', stdout);
		fputs(fields[FIELD_NAME], stdout);
		putc('|', stdout);
		fputs(ver, stdout);
		putc('|', stdout);
		if (rev != '\0') {
			fputs(rev, stdout);
			rev[0] = '\0';
		}
		putc('|', stdout);
		fputs(fields[FIELD_SECT], stdout);
		putc('|', stdout);
		/* some packages have no installed size, only package size -
		 * libc6-ppc64el-cross in belenos */
		if (fields[FIELD_SIZE] == NULL)
			fwrite("0K|", 1, 3, stdout);
		else {
			fputs(fields[FIELD_SIZE], stdout);
			fwrite("K|", 1, 2, stdout);
		}
		fputs(fields[FIELD_PATH], stdout);
		putc('|', stdout);
		fputs(fname, stdout);
		putc('|', stdout);

		if (fields[FIELD_DEPS] != NULL) {
			ndeps = 0;
			dep = fields[FIELD_DEPS];

			do {
				pos = strstr(dep, ", ");
				if (pos != NULL) pos[0] = '\0';

				sep = strstr(dep, " (");
				/* special case, in case there's an OR relationship between
				 * dependencies 0setup replaces the | character with a space */
				if (sep == NULL)
					sep = strchr(dep, ' ');
				else
					strchr(sep + 2, ')')[0] = '\0';
				if (sep != NULL) sep[0] = '\0';

				depcrc = crc32(initcrc, (unsigned char *) dep, strlen(dep));

				/* if the package is an invalid dependency, skip it */
				for (i = 0; i < nbaddeps; ++i)
					if (depcrc == baddeps[i]) goto nextdep;

				/* check whether the package exists */
				if (npkgs > 0) {
					for (i = 0; i < npkgs; ++i)
						if (depcrc == pkgs[i]) goto parse_deps;

					/* if not - add it to the list of bad dependencies */
					if (baddepf != NULL) {
						fputs(dep, baddepf);
						fputc('\n', baddepf);
					}
					goto nextdep;
				}

/* parse_deps */
parse_deps:
				deprel = NULL;
				if (sep != NULL) {
					sep += 2;
					if (sep[0] == '>') {
						if (sep[1] == '=') {
							trim_ver(sep + 3, &preg, &depver, NULL);
							deprel = "&ge";
						} else if (sep[1] == '>') {
							trim_ver(sep + 3, &preg, &depver, NULL);
							deprel = "&gt";
						} else deprel = NULL;
					} else if (sep[0] == '<') {
						if (sep[1] == '=') {
							trim_ver(sep + 3, &preg, &depver, NULL);
							deprel = "&le";
						}
					} else if (sep[0] == '=') {
						trim_ver(sep + 2, &preg, &depver, NULL);
						deprel = "&eq";
					}
					sep[0] = '\0';
				}

				++ndeps;
				if (ndeps > 1)
					fwrite(",+", 1, 2, stdout);
				else
					putc('+', stdout);

				fputs(dep, stdout);
				if (deprel != NULL) {
					fputs(deprel, stdout);
					fputs(depver, stdout);
				}

/* nextdep */
nextdep:
				if (pos == NULL) break;
				dep = pos + 2;
			} while (1);
		}

		putc('|', stdout);
		fputs(fields[FIELD_DESC], stdout);
		putc('|', stdout);
		fputs(argv[1], stdout);
		putc('|', stdout);
		fputs(argv[2], stdout);
		fwrite("|\n", 1, 2, stdout);

		/* write the homepage to the homepage list */
		if (fields[FIELD_WWW][0] != '\0') {
			fputs(fields[FIELD_NAME], wwwf);
			putc(' ', wwwf);
			fputs(fields[FIELD_WWW], wwwf);
			putc('\n', wwwf);
		}

/* cleanup */
cleanup:
		for (i = 0; i < FIELD_MAX; i++) fields[i][0] = '\0';

	} while (line != NULL);

	/*************************
	 **** END OF BIG LOOP ****
	 *************************/

	for (i = sizeof(fields) / sizeof(fields[0]) - 1 ; 0 <= i; --i)
		free(fields[i]);

	if (baddeps != NULL)
		free(baddeps);
	else {
		fclose(baddepf);
		free(pkgs);
	}

	free(buf);
	free(outbuf);
	free(inbuf);
	fclose(wwwf);
	fclose(db);

	regfree(&preg);

	return EXIT_SUCCESS;
}

/* EOF */