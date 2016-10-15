Woof - GPL2
----

Woof is a "Puppy builder". What this means is you can build your own custom
Puppy Linux live-CD from the binary packages of another distro.

Currently supported: Ubuntu, Debian, Slackware, Puppy (pet pkgs)
What you get looks and feels just like Puppy, is Puppy.

Preparation
-----------

1. Suitable build environment
If you are reading this then you have expanded the 'woof' tarball. But, be sure
that this is done in a Linux partition. A Windows/DOS FAT or NTFS partition will
not work! Also, the partition needs lots of space, I suggest 10GB.

2. Host operating system
You must be running in a Linux environment.
It is advised that you that latest woofce releases since these
are tested distros..

3. Choose a compatible-distro.
This is the distro whose packages you are going to 'borrow' to build your Puppy.
Open file DISTRO_SPECS in a text editor and change this line:
DISTRO_BINARY_COMPAT="ubuntu"
to what you want, 'ubuntu', 'debian', 'slackware' or 'puppy'.

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
# ./2createpackages

3. Build Puppy live-CD
This gets built in a directory named 'sandbox3' and as well as the live-CD iso
file you will also find the individual built files and the 'devx' file.
# ./3builddistro

Building a Puppy: using the GUI
-------------------------------
The GUI is under development..

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
Notice that there are 'Packages-puppy-noarch-official',
also 'Packages-puppy-common-official'

The single-digit '-2-', '-3-', '-4-', '-5-' files reside on ibiblio.org also.
These files list the complete contents of each repository.


Puppy filenames
===============

The main Puppy files are:

  vmlinuz, initrd.gz, puppy.sfs, zdrv.sfs, fdrv.sfs, adrv.sfs, ydrv.sfs

Versioning is put into the last two, for example:

  vmlinuz, initrd.gz, puppy_slacko_7.0.0, zdrv_slacko_7.0.0.sfs
  fdrv_slacko_7.0.0.sfs, adrv_slacko_7.0.0.sfs, ydrv_slacko_7.0.0.sfs

...those last two names are intended to be unique for that build of Puppy,
so they can be found at bootup.

DISTRO_SPECS file
=================

The filenames are stored in the built Puppy, in /etc/DISTRO_SPECS.
For example:

DISTRO_PUPPYSFS='puppy_slacko_7.0.0.sfs'
DISTRO_ZDRVSFS='zdrv_slacko_7.0.0.sfs'
DISTRO_FDRVSFS='fdrv_slacko_7.0.0.sfs'
DISTRO_ADRVSFS='adrv_slacko_7.0.0.sfs'
DISTRO_YDRVSFS='ydrv_slacko_7.0.0.sfs'

So, any script that wants to know what the names are can read these variables.

Woof 3builddistro also copies DISTRO_SPECS into the initrd.gz,
so that the 'init' script can see what files to search for.

However, in a running Puppy, you can find out the filenames in the way
that scripts have done before, by reading 'PUPSFS' and 'ZDRV' variables
in /etc/rc.d/PUPSTATE.

In fact, to clarify the difference between these two sets of variables,
I have put this comment into /etc/DISTRO_SPECS:

  #Note, the .sfs files below are what the 'init' script in initrd.gz searches for,
  #for the partition, path and actual files loaded, see PUPSFS and ZDRV in /etc/rc.d/PUPSTATE

--------------
Regards,
Barry Kauler
puppylinux.com
