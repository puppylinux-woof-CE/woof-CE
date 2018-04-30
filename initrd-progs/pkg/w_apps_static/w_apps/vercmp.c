/* vi: set sw=4 ts=4: */
/*
 * libdpkg - Debian packaging suite library routines
 * vercmp.c - comparison of version numbers
 *
 * Copyright (C) 1995 Ian Jackson <iwj10@cus.cam.ac.uk>
 *
 * Licensed under GPLv2, see file LICENSE in this source tree
 * 
 * location: woof-arch/<arch>/target/rootfs-skeleton/bin/vercmp
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

static int ver_cmp(const char *val, const char *ref)
{
	int vc, rc;
	long vl, rl;
	const char *vp, *rp;
	const char *vsep, *rsep;

	for (;;) {
		vp= val;  while (*vp && !isdigit(*vp)) vp++;
		rp= ref;  while (*rp && !isdigit(*rp)) rp++;
		for (;;) {
			vc= val == vp ? 0 : *val++;
			rc= ref == rp ? 0 : *ref++;
			if (!rc && !vc) break;
			if (vc && !isalpha(vc)) vc += 256; /* assumes ASCII character set */
			if (rc && !isalpha(rc)) rc += 256;
			if (vc != rc) return vc - rc;
		}
		val= vp;
		ref= rp;
		vl=0;  if (isdigit(*vp)) vl= strtol(val,(char**)&val,10);
		rl=0;  if (isdigit(*rp)) rl= strtol(ref,(char**)&ref,10);
		if (vl != rl) return vl - rl;

		vc = *val;
		rc = *ref;
		vsep = strchr(".-", vc);
		rsep = strchr(".-", rc);
		if (vsep && !rsep) return -1;
		if (!vsep && rsep) return +1;

		if (!*val && !*ref) return 0;
		if (!*val) return -1;
		if (!*ref) return +1;
	}
}

int main (int argc, char **argv)
{
	int r, res;
	if (argc < 4 || *argv[1] == '\0' || *argv[3] == '\0') {
		printf("version1 lt|gt|le|ge|eq version2\n");
		printf("return value 0 if true, else 1\n\n");
		printf("l = less, g = greater, t = than, e|eq = equal\n");
		return 1;
	}
	r = ver_cmp(argv[1], argv[3]);

	if      (!strcmp(argv[2], "le")) res = !(r <= 0);
	else if (!strcmp(argv[2], "ge")) res = !(r >= 0);
	else if (!strcmp(argv[2], "lt")) res = !(r < 0);
	else if (!strcmp(argv[2], "gt")) res = !(r > 0);
	else if (!strcmp(argv[2], "eq")) res = !(r == 0);
	else { printf("unknown operator: %s", argv[2]); return 1; }

	//printf("%s\n", res == 0 ? "true" : "false");
	return res;
}
