14 June 2012
------------
I downloaded an image for the Raspberry Pi. It was compiled in Gentoo and the
compressed image was 2GB, needing a 8GB SD card.
It ran well on the RasPi and I was able to compile many packages, for the purpose
of creating the 'common' PETs required for all puppies.

I decided to extract all of the packages in the Gentoo image, and convert them
to PETs. The packages are extracted from the SD card by 'createpkgs', about
440 of them.

The script 'createpets' converts the extracted binary packages to PET packages.

These scripts are not run inside the Woof working directory, set them up somewhere
else. Read the scripts for further info.

Regards,
Barry Kauler

15 June 2012
------------
Forget about 'createpets', the conversion is not really good enough.
Anyway, I think it better to keep the Gentoo bin packages as foreign "compat distro"
packages, not convert them to PETs -- keeps everything conceptually cleaner.

Therefore, after running 'createpkgs', I then ran 'createtbz' which simply makes
the pkgs into .tar.bz2 files and creates a db entry.

The default settings are the tarballs are created in directory 'packages-gentoo-gap6'
and the db file is 'Packages-gentoo-gap6-official'.
The directory can be copied to where Woof can access it, normally in local-repositories/arm/
The db file can be copied to woof2/woof-distro/arm/
