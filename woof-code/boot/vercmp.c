/*
 * libdpkg - Debian packaging suite library routines
 * vercmp.c - comparison of version numbers
 *
 * Copyright (C) 1995 Ian Jackson <iwj10@cus.cam.ac.uk>
 *
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2,
 * or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with dpkg; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
 /*BK modified april 2011*/
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

# define _(Text) Text

struct versionrevision {
  unsigned long epoch;
  char *version;
  const char *revision;
};  

static int verrevcmp(const char *val, const char *ref) 
{
  int vc, rc;
  long vl, rl;
  const char *vp, *rp;
  const char *vsep, *rsep;

  if (!val) val= "";
  if (!ref) ref= "";
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

int versioncompare(const struct versionrevision *version,
                   const struct versionrevision *refversion) 
{
  int r;

  if (version->epoch > refversion->epoch) return 1;
  if (version->epoch < refversion->epoch) return -1;
  r= verrevcmp(version->version,refversion->version);  if (r) return r;
  r= verrevcmp(version->revision,refversion->revision); if (r) return r;
  return r;
}

int versionsatisfied3(const struct versionrevision *it,
                      const struct versionrevision *ref,
                      const char *op) 
{
  int r;
  r= versioncompare(it,ref);
  if (strcmp(op, "le") == 0 || strcmp(op, "<") == 0)
    return r <= 0;
  if (strcmp(op, "ge") == 0 || strcmp(op, ">") == 0)
    return r >= 0;
  if (strcmp(op, "lt") == 0)
    return r < 0;
  if (strcmp(op, "gt") == 0)
    return r > 0;
  if (strcmp(op, "eq") == 0)
    return r == 0;
  fprintf(stderr, "unknown operator: %s", op);

  exit(1);
}

const char *parseversion(struct versionrevision *rversion, const char *string) 
{
  char *hyphen, *colon, *eepochcolon;
  unsigned long epoch;

  if (!*string) return _("version string is empty");
  
  colon= strchr(string,':');
  if (colon) {
    epoch= strtoul(string,&eepochcolon,10);
    if (colon != eepochcolon) return _("epoch in version is not number");
    if (!*++colon) return _("nothing after colon in version number");
    string= colon;
    rversion->epoch= epoch;
  } else {
    rversion->epoch= 0;
  }

  rversion->revision = "";

  rversion->version= malloc(strlen(string)+1);
  strcpy(rversion->version, string);

#if 0
  fprintf(stderr,"Parsed version: %lu, %s\n",
	  rversion->epoch,
	  rversion->version);
#endif
	  
  return 0;
}

int main(int argc, char *argv[]) 
{
  const char *err;
  struct versionrevision ver, ref;

  if (argc < 4) {
    fprintf(stderr, "usage: %s version1 lt|gt|le|ge|eq version2\n       return value 0 if true, else 1\n", argv[0]);
    return 2;
  }

  err = parseversion(&ver, argv[1]);
  if (err) {
    fprintf(stderr, "Invalid version `%s': %s\n", argv[1], err);
    return 2;
  }
    
  err = parseversion(&ref, argv[3]);
  if (err) {
    fprintf(stderr, "Invalid version `%s': %s\n", argv[3], err);
    return 2;
  }

  return ! versionsatisfied3(&ver, &ref, argv[2]);
}
