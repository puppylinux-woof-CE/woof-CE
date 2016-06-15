Woof
----

Woof is a "Puppy builder". What this means is you can build your own custom
Puppy Linux live-CD from the binary packages of another distro.

Currently supported: Ubuntu, Debian, Slackware, Arch, T2, Puppy

What you get looks and feels just like Puppy, is Puppy. The default selection
of packages gives you a live-CD ISO file about 100MB - 130MB. You also get the
freedom and speed of Puppy, and none of the disadvantages that you may have
perceived with the other distros. 

Notice that 'Puppy' is in the list. It may seem a bit "circular" but yes, the
compatible-distro can be one of the Puppy-releases, so you could build a Puppy
live-CD with 100% PET packages. Wary Puppy is built this way.

Preparation
-----------

1. Suitable build environment
If you are reading this then you have expanded the 'woof' tarball. But, be sure
that this is done in a Linux partition. A Windows/DOS FAT or NTFS partition will
not work! Also, the partition needs lots of space, I suggest 10GB.

2. Host operating system
You must be running in a Linux environment.
The Linux distro that you are running rght now may have inadequate or missing
'dpkg-deb' and 'lzma' utilities. This problem also applies to Puppy Linux <= v4.
Place 'support/dpkg-deb' into /bin and 'support/lzma' into /usr/bin, replacing any other
versions (first run 'which' to check they aren't existing elsehwere).

NOTICE: Woof is currently only supported in a running Puppy 4.3+ environment.
        Do not use any other Linux distro.

3. Choose a compatible-distro.
This is the distro whose packages you are going to 'borrow' to build your Puppy.
Open file DISTRO_SPECS in a text editor and change this line:
DISTRO_BINARY_COMPAT="ubuntu"
to what you want, 'arch', 'ubuntu', 'debian', 'slackware', 't2' or 'puppy'.

Building a Puppy: using the commandline scripts
-----------------------------------------------

0. Download package database files
You must have broadband Internet access.
Open a terminal in the 'woof' directory, then run '0setup':
# ./0setup

###PENDING###
1a. OPTIONAL: Tweak common PET package selection
# ./1choosepackages
You can edit the variable PKGS_SPECS_TABLE in file DISTRO_PKGS_SPECS-* to choose
the packages that you want in your build. '1choosepackages' is a GUI that might
make it easier to fiddle with the choices of "common" PET packages, which is
those PETs that are used in all Puppy builds.
Note, file Packges-puppy-common-official is the database of the common PETs.

1. Download packages
About 500MB drive space is required, but this may vary enormously
depending on the package selection.
# ./1download

2. Build the cut-down generic Puppy-packages
This will take 2 - 3 hours, depending on your PC. A reasonably modern fast PC
with CPU >= 1.5GHz and >= 256MB RAM is recommended.
# ./2createpackages

3. Build Puppy live-CD
This gets built in a directory named 'sandbox3' and as well as the live-CD iso
file you will also find the individual built files and the 'devx' file.
# ./3builddistro

Building a Puppy: using the GUI
-------------------------------

NOTICE, OCTOBER 2009:
The GUI is under heavy development.
Currently only tested building from compat-distro Puppy-4 PET pkgs.

I have written a frontend GUI for the above scripts (and then some).
The GUI is also a frontend for all of the configuration files, so you
should not have to directly edit any of them (or that's the plan anyway).
It is a work-in-progress, but quite usable, and I recommend that you use the
GUI interface rather than the commandline scripts, especially when new to Woof.

# ./woof_gui

It will come up with a tabbed-interface, and basically you go from left-tab
to right-tab.

For newcomers, I recommend that you perform a run-through without making any
changes, to confirm that everything works. By default, Woof is configured
to build Puppy 4.3+ from 4.x PET packages only (the compatible-distro is set
to 'puppy'). 

Newcomer instructions:

SKIP THIS IF LATEST WOOF: 'Download dbs' tab: click the 'UPDATE' button.
'Download pkgs' tab: click the 'DOWNLOAD' button.
'Build pkgs' tab: click the 'BUILD ALL' button.
'Kernel options' tab: choose the latest kernel.
'Build distro' tab: click the 'BUILD DISTRO' button.

...then you will have a Puppy 4.3+ live-CD ISO file and a 'devx' SFS file!

LEGAL
-----

Woof is (c) copyright Barry Kauler 2009, puppylinux.com
Woof is free, at this stage a specific distribution licence is not decided.
However, Woof consists of components that are under various 'GPL' licences
and builds from 'GPL' and various 'free' binary packages, so the final
build of Puppy will be in conformance with those and as stated in the Puppy
'rootfs-skeleton/usr/share/doc/index.html' file.

------------------------------------------------------------------------------

TECHNICAL NOTES
---------------


packages-templates directory
----------------------------

any directory in the template, the files in the target pkg will be cut down to the same selection.
(even if empty dir). Exception, file named 'PLUSEXTRAFILES' then target will have all files from deb.
  0-size file, means get file of same name from deb (even if in different dir) to target.
  non-zero file, means copy this file from template to target.
  template files with '-FULL' suffix, rename target file also (exs: in coreutils, util-linux).
  
Any dir in template with 'PKGVERSION' in name, substitute actual pkg version number in target dir.
Except for /dev, /var, all dirs in target are deleted to only those in template, except
  if file 'PLUSEXTRADIRS' is found in template.
  
As a last resort, if target pkg is wrong, a file 'FIXUPHACK' is a script that can be at top dir
  in template. It executes in target, with current-dir set to where FIXUPHACK is located. (ex: perl_tiny).
  Ran into problem slackware post-install scripts messing things up. See near bottom of '2createpackages'
  how damage is limited. Also DISABLE_POST_INSTALL_SCRIPT=yes in FIXUPHACK to disable entirely.
  
If a dir in template has files in it then target is cut down (unless PLUSEXTRAFILES present),
 however there are some exceptions (such as .so regular files). To not allow any exceptions,
 place NOEXCEPTIONFILES in the template dir (ex: glibc usr/lib/gconv).
 I needed to finetune this some more -- example packages-templates/gettext/usr/lib, have
 NOEXCEPTIONFILES, but do want all of libasfprint.so.* whatever the version numbers are,
 so can now create zero-size file 'libasfprint.so.STARCHAR' to achieve this.

Packages-puppy-*
----------------

Notice that there are 'Packages-puppy-2-official' and 'Packages-puppy-2xx-official',
also 'Packages-puppy-4-official' and 'Packages-puppy-4xx-official'.

The '-2xx-' and '-4xx-' database files are local only, used in Woof only.
These files do not get uploaded to ibiblio.org.
They are used for building a "compatible-distro" from PET packages.
The 'DISTRO_PKGS_SPECS-puppy-2' and 'DISTRO_PKGS_SPECS-puppy-4' specify these database files.

The single-digit '-2-', '-3-', '-4-', '-5-' files reside on ibiblio.org also.
These files list the complete contents of each repository.

The reason for having a '-2xx-' as well as a '-2-' database files is because
the latter is a complete record of what is in 'pet_packages-2' directory on
ibiblio.org, whereas the former lists packages being used to build the Puppy
live-CD.


Regards,
Barry Kauler
puppylinux.com
