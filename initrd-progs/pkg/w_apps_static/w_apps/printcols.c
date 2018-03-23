/*
 * (c) Copyright Barry Kauler 2009
 * Invoke like this: printcols afilename 1 6 2 9
 *  ...columns with '|' delimiter character get printed, in order specified.
 *     handles up to 15 columns.
 * Designed for use in the Puppy Package Manager, puppylinux.com
 * 
 * Compile statically:
 # diet gcc -nostdinc -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o printcols -o printcols printcols.c
 * OR
 * musl-gcc -static -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o printcols printcols.c
 *
 * then:
 * strip --strip-all -R .note -R .comment
 *
 * location: woof-arch/<arch>/build/support/printcols
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define BUF_SIZE (1024 * 1024 * 1)
#define LINE_SIZE BUF_SIZE

int main (int argc, char ** argv) {
	int cntargs;
	char *buffer1;
	char *buffer2;
	FILE* fp;
	char *ptokens[15];
	int i;
	int cnt;
	int max=0;
	int nextarg;
	int args[15];

	char *appname = strrchr(argv[0], '/');
	if (appname) {
		appname++;
	} else {
		appname = argv[0];
	}
	if (argc < 3) {
		printf("syntax: %s <file> <column1> [column2] etc\n", appname);
		return 1;
	}

	for (cntargs = 2; cntargs < argc; ++cntargs) {
		args[cntargs] = atoi(argv[cntargs]);
		if (cntargs == 2) {
			max = args[cntargs];
		} else {
			max = args[cntargs] > max ? args[cntargs] : max;
		}
	}

	fp = fopen(argv[1],"r");
	if (!fp) {
		printf("%s: Error opening %s\n", appname, argv[1]);
		return 1;
	}

	buffer1 = malloc(LINE_SIZE);
	buffer2 = malloc(BUF_SIZE);

	while( fgets(buffer1,LINE_SIZE,fp) != NULL ) {

		cnt=1;

		ptokens[0] = buffer1;
		i = 0;
		while (buffer1[i] != '\0' && cnt<=max) {
			if (buffer1[i] == '|') {
				buffer1[i] = '\0';
				ptokens[cnt]=&buffer1[i+1];
				++cnt;
			}
			++i;
		}

		/*print the fields in requested order...*/
		for (cntargs=2; cntargs < argc; ++cntargs) {
			nextarg=args[cntargs];
			if ( nextarg >= cnt ) { /*in case of lines with less fields*/
				putc('|', stdout);
				continue;
			}
			fputs(ptokens[nextarg - 1], stdout);
			putc('|', stdout);
		}
		putc('\n', stdout);
	}

	fclose(fp);
	free(buffer2);
	free(buffer1);
	return 0;
}

