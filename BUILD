1. "pkglist" aka "package list" aka the list of packages that will be assembled into the puppy.sfs:
--> located in your workdir, the filename is "basesfs"

2. The directories in the tarball:
-  builder -> builder scripts (builders for .deb and .txz packages), scripts to make packages (.txz and .deb), scripts to prepare a repository which you can "ftp-upload" to somewhere else
- kernel-kit -> supposedly to compiler kernel, this is part of Woof-CE proper; I didn't modify it for woof-next and I don't use it.
- woof-arch -> arch-dependent programs (mostly compiled binaries, there are ones for x86, x86_64, arm)
- woof-code -> arch-independent programs (mostly scripts, like SNS, etc)
- woof-distro -> specification to build based on a particular parent distro. Contains default pkglist (basesfs) and location of the repository URL

woof-code is most interesting. In it, you will find:
- boot -> this is puppy's initrd in "exploded" form 
- kernel-skeleton -> original Woof-CE hacks for firmware loading, not used (the "huge kernel" mode replaces this)
- rootfs-packages -> contains packages in "exploded" form (=dirs + pinstall.sh script).
- rootfs-skeleton -> puppy's scripts
- woof2-scripts_and_files -> Woof-CE original build scripts, not used, left for reference purposes

what's inside "rootfs-packages"?
These are the places where you can add your hacks and custom stuff, if you don't want to build a proper package for it. What are the current ones?
- debian-setup -> contains adaptation that must be done to debian-based distros to make it boot/work.
- pthemes -> should be obvious what this is
- rox-filer-data -> should also be obvious
- slack-setup -> contains adaptation that must be done to make slackware-based distros to make it work/boot

These "rootfs-packages" are added into the build chroot when you use the "directive" %addpkg in the pkglist. For example, for in the pkglist for devuan, you will see "%addpkg debian-setup" which means import and install "debian-setup" package which is located in the woof-code/rootfs-skeleton/debian-setup package.

3. Some clarifications for the commands used in pkglist. Note that different parent distro supports different commands; e.g. debian-based pkglist has "%depend" command which activatest dependency-tracking (e.g. installing a package will also install its dependencies); while slackware-based pkglist doesn't have this command because, well, slackware packages do not have dependency tracking encoded into it.

Common commands:
%include -> include another file
%makesfs -> run mksquashfs and create SFS of chroot

%repo -> specificy additional repositories (obsolete, this should be done by updating repo-url instead)
%import  -> copy over a given directory to chroot (similar to %addpkg, but does not support pinstall.sh and the copy is not registered as a package)
%addpkg  -> copy over a given directory to chroot, run pinstall.sh, and record this as a "package" (which means they will be visible by the package management tools and can be un-installed)
%reinstall -> re-install a given package
%remove    -> remove an already installed package (perhaps pulled automatically by dependency, etc)

%addbase -> install rootfs-skeleton (puppy scripts)
%bblinks -> install busybox symlinks (obviously you must already install busybox before this can work)
%cutdown -> try to reduce size by moving components outside the main chroot to elsewhere

%symlink -> make a symlink
%rm    -> remove a file
%mkdir -> make a directory
%touch -> create an empty file
%chroot -> run a given common inside the build chroot
%exit -> stop processing pkglist here and ignore the rest of the file (useful for debugging)

--- additional commands for debian-based distro only:
%lock -> lock package so they cannot be updated
%depend -> turn on dependency tracking
%nodepend -> turn off dependency tracking
%pkg_by_prio -> install packages given by the named "priority" (or category).

%bootstrap -> install packages using simulated dpkg
%dpkg      -> install packages using dpkg (dpkg must be installed in host system)
%dpkgchroot -> install packages using dpkg installed in chroot (obviously you must already install "dpkg" package before this can work)
%dpkg_configure -> run dpkg-reconfigure
