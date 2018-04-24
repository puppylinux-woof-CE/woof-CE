CC = gcc
#CC = musl-gcc
STATIC = -static

all: cddetect \
	daemon \
	debdb2pupdb \
	elspci \
	fakelogin \
	find_cat \
	findpkgs-dep-helper \
	findpkgs-search-helper \
	zinit \
	printcols \
	pup_event_frontend_d \
	syslog \
	vercmp

daemon:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o daemon daemon.c

debdb2pupdb:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o debdb2pupdb debdb2pupdb.c

cddetect:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o cddetect cddetect.c

elspci:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o elspci elspci.c

fakelogin:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o fakelogin fakelogin.c

find_cat:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o find_cat find_cat.c

findpkgs-dep-helper:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o findpkgs-dep-helper findpkgs-dep-helper.c

findpkgs-search-helper:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o findpkgs-search-helper findpkgs-search-helper.c

printcols:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o printcols printcols.c

pup_event_frontend_d:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o pup_event_frontend_d pup_event_frontend_d.c

syslog:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o syslog syslog.c

vercmp:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o vercmp vercmp.c

zinit:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o zinit zinit.c

clean:
	rm -f cddetect daemon debdb2pupdb elspci fakelogin find_cat findpkgs-dep-helper findpkgs-search-helper zinit printcols syslog vercmp pup_event_frontend_d
