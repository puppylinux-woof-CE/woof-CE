CC = gcc
#CC = musl-gcc
STATIC = -static

all: daemon debdb2pupdb elspci fakelogin find_cat findpkgs-dep-helper zinit printcols syslog vercmp

daemon:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o daemon daemon.c

debdb2pupdb:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o debdb2pupdb debdb2pupdb.c

elspci:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o elspci elspci.c

fakelogin:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o fakelogin fakelogin.c

find_cat:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o find_cat find_cat.c

findpkgs-dep-helper:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o findpkgs-dep-helper findpkgs-dep-helper.c

printcols:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o printcols printcols.c

syslog:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o syslog syslog.c

vercmp:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o vercmp vercmp.c

zinit:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o zinit zinit.c

clean:
	rm -f daemon debdb2pupdb elspci fakelogin find_cat findpkgs-dep-helper zinit printcols syslog vercmp
