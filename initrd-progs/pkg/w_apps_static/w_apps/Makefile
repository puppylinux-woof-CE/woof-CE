CC = gcc
#CC = musl-gcc
STATIC = -static

all: cddetect \
	debdb2pupdb \
	find_cat \
	findpkgs-dep-helper \
	findpkgs-search-helper \
	printcols \
	pup_event_frontend_d \
	vercmp

debdb2pupdb:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o debdb2pupdb debdb2pupdb.c

cddetect:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o cddetect cddetect.c

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

vercmp:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o vercmp vercmp.c

clean:
	rm -f cddetect debdb2pupdb find_cat findpkgs-dep-helper findpkgs-search-helper printcols vercmp pup_event_frontend_d
