# woof - the Puppy builder

Currently supported:

| Distro        | Version       | Architecture | Status   |
| ------------- | ------------- | -------------| -------- |
| Slackware     | 15.0          | x86_64, x86  | [![slackware-s15pup](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/slackware-s15pup.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/slackware-s15pup.yml) |
| Slackware     | 14.2          | x86_64, x86  | [![slackware-14.2](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/slackware-14.2.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/slackware-14.2.yml) |
| Ubuntu        | 22.04         | x86_64       | [![ubuntu-jammy64](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/ubuntu-jammy64.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/ubuntu-jammy64.yml) |
| Ubuntu        | 20.04         | x86_64       | [![ubuntu-focal64](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/ubuntu-focal64.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/ubuntu-focal64.yml) |
| Debian        | Unstable      | x86_64       | [![debian-sid64](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-sid64.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-sid64.yml) |
| Debian        | Testing       | x86_64       | [![debian-trixie](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-trixie.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-trixie.yml) |
| Debian        | 12            | x86_64, x86  | [![debian-bookworm](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-bookworm.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-bookworm.yml) |
| Debian        | 11            | x86_64, x86  | [![debian-bullseye](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-bullseye.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/debian-bullseye.yml) |
| Devuan        | 5.0           | x86_64       | [![devuan-daedalus64](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/devuan-daedalus64.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/devuan-daedalus64.yml) |
| Devuan        | 4.0           | x86_64       | [![devuan-chimaera64](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/devuan-chimaera64.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/devuan-chimaera64.yml) |
| Void          | -             | x86_64, x86  | [![void-voidpup](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/void-voidpup.yml/badge.svg)](https://github.com/puppylinux-woof-CE/woof-CE/actions/workflows/void-voidpup.yml) |

# Building a Puppy: using GitHub Actions

Puppy can be built directly on GitHub, saving the hassle of preparing a suitable build environment on a fast machine with adequate storage.

0. Fork woof-CE.

1. Clone your fork.

2. Modify woof-CE, commit your changes and push them.

3. [Trigger a woof-CE run on GitHub Actions](https://github.com/puppylinux-woof-CE/woof-CE/wiki/Building-a-Puppy-on-GitHub).

4. Download your Puppy from the newly published release.

5. Test your Puppy and open a pull request to woof-CE, if you want your changes to be officially incorporated into woof-CE.

# Contributing to woof-CE: using Gitpod

To modify woof-CE and push the changes to GitHub without having to set up a local development environment: [![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/puppylinux-woof-CE/woof-CE)

Not all of woof-CE can run [without root access](https://github.com/gitpod-io/gitpod/issues/39), but most of woof-CE works on Gitpod and it's possible to [boot Puppy inside QEMU and control it over VNC](https://www.gitpod.io/blog/native-ui-with-vnc/), all through the browser.

To work on woof-CE in a fork, through Gitpod:

1. Fork woof-CE.

2. Browse to `https://gitpod.io/#https://github.com/your-github-username/woof-CE`.

# Directory Structure

Woof-CE has five directories:

- woof-arch   : architecture-dependent (x86_64, x86, ARM) files, mostly binary executables.
- woof-code   : the core of Woof.
  - 0setup
  - 1download
  - 2createpackages
  - 3builddistro
  - support            :  various helper scripts used by 0setup, 1download, 2createpackages and 3builddistro.
  - rootfs-skeleton    :  the Puppy file system skeleton, which includes core scripts like sfs_load and configuration files like /etc/passwd.
  - rootfs-packages    :  additional Puppy packages, like the network wizard, that can be included in the build.
  - packages-templates :  recipes used by woof-CE to make compatible-distro packages work under Puppy and reduce their size.
  - rootfs-petbuilds   :  recipes used by woof-CE to build packages from source.
- woof-distro : architecture (x86_64, x86, etc.) and distro specific (Debian, Slackware, etc.) configuration files.
  - `DISTRO_SPECS`          : metadata like the name and version number of the built Puppy distro.
  - `DISTRO_PKGS_SPECS-*`   : the list of prebuilt (compat distro or PET) packages to include in the build.
  - `DISTRO_COMPAT_REPOS-*` : the list of compat distro repos to download packages from.
  - `DISTRO_PET_REPOS-*`    : the list of PET package repos to download packages from.
  - `_00build.conf`         : additional settings like the default theme, custom commands to run at the end of the build and a list of packages to build from source during the build.
  - `_00build_2.conf`       : overrides settings defined in `_00build.conf`.
- kernel-kit  : scripts to download, patch, configure and build the kernel.
  - `configs_*`          : kernel .config files.
  - `debian-diffconfigs` : .config file fragments for use with ./scripts/kconfig/merge_config.sh, which can be used to build a Puppy-compatible kernel from the Debian kernel source.
  - `build.conf`         : a configuration file that specifies the kernel .config file to use and determines whether or not aufs is included in the build.
  - `build.sh`           : builds the kernel based on the configuration defined in build.conf.
- initrd-progs: scripts and files to generate the initial ramdisk

# Preparation

1. Suitable build environment
  - Linux partition
  - At least 6-10GBs of space

2. Host operating system
  - A recent Woof-CE puppy with the devx (compilers, headers and other development tools) installed. Otherwise use [run_woof](https://github.com/puppylinux-woof-CE/run_woof).
  
3. A `woof-out_*` working directory

The `merge2out` script merges woof-CE's core from `woof-code`, prebuilt binaries from `woof-arch` and configuration files from `woof-distro/$arch/$distro/$version` to into a directory named `woof-out_*` where you can run woof-CE. You then `cd` into `woof-out_*` and run the build scripts.

The great thing about this merge operation is that you can choose exactly what you want to go into woof-out. You can choose the host system that you are building on (usually x86_64), the target (exs: x86_64 x86, ARM), the compatible-distro (ex: slackware), and the compat-distro version (ex: 15.0). So, you create woof-out without any confusing inappropriate content.

So, to get going with woof-CE, open a terminal and do this:

    ./merge2out
    cd ../woof-out_*

# Building a Puppy: building the kernel

This is an optional step that can be skipped if you wish to use a prebuilt kernel in your woof-CE build.

Open a terminal in the `woof-out_*` directory.

0. Switch to the kernel-kit directory

       cd kernel-kit

1. Modify build.conf or replace it with one of `*-build.conf`

2. Run kernel-kit

       ./build.sh

The output should be available in `kernel-kit/output` and 3builddistro can use it instead of downloading a prebuilt kernel.

# Building a Puppy: using the commandline scripts

Open a terminal in the `woof-out_*` directory.

0. Download package database files

       ./0setup

OPTIONAL: Tweak package selection. You can edit the variable PKGS_SPECS_TABLE in file `DISTRO_PKGS_SPECS-*` and the variable PETBUILDS in file `_00build.conf` to choose the packages that you want in your build.

1. Download packages

       ./1download

About 500MB drive space is required, but this may vary enormously depending on the package selection.

2. Build the cut-down generic Puppy-packages

       ./2createpackages

3. Build Puppy live-CD

       ./3builddistro

This gets built in a directory named `sandbox3` and as well as the live-CD ISO file you will also find the individual built files and the `devx` file.

# Branding and Artwork

The human-readable distro name (DISTRO_NAME), version (DISTRO_VERSION) and file name prefix (DISTRO_FILE_PREFIX) are specified in `DISTRO_SPECS`.

3builddistro takes the distro logo that appears in documentation and first-run dialogs from `woof-code/rootfs-skeleton/usr/share/doc/puplogos`. It looks for `${DISTRO_FILE_PREFIX}.svg` or `${DISTRO_BINARY_COMPAT}.svg`, then falls back to a generic Puppy logo.

There are two ways to specify the artwork (window manager theme, GTK+ theme, icon theme, wallpaper and cursor theme) to use by default, both via `_00build.conf`:

1. Using pTheme: choose one of the global themes under `/usr/share/ptheme/globals`.

       PTHEME="Original Pup"

2. Using `support/choose_themes`: specify default themes individually.

       THEME_WALLPAPER="Blue.svg"
       THEME_GTK2="Flat-grey-rounded"
       THEME_JWM="Flat-grey"
       THEME_JWM_BUTTONS="Buntu"
       THEME_GTK_ICONS="Puppy Standard"
       THEME_DESK_ICONS="StandardSvg"
       THEME_MOUSE="DMZ-Black"

See `support/choose_themes` for a list of theme directories.

Themes are not downloaded automatically by woof-CE and must be added to the build as binary packages or built from source during the build.

# Adding Binary Packages

The list of binary packages to include in the distro is specified in `DISTRO_PKGS_SPECS-*`. See `woof-code/README.pkgs_specs` for more details.

# Building Packages from Source

woof-CE implements a "petbuilds" mechanism in `woof-code/support/petbuilds.sh`. It builds packages from source inside a chroot environment of the built Puppy distro (with its `devx`), so the built packages are reproducible, guaranteed to be compatible with the built Puppy and customizable.

This mechanism is useful when:

1. A package must be customized to work in Puppy: for example, some applications refuse to run as root.

2. A package is not available in the compat distro repos: for example, many Puppy tools rely on gtkdialog, but it's a Puppy-specific tool not available in other distros.

3. An application is available in the compat distro repos, but it's too old for use in Puppy: for example, some Puppy JWM themes won't work if JWM is too old.

4. An application is available in the compat distro repos, but the compat distro enables optional features that add unwanted dependencies, making the compat distro package bigger and heavier than a much smaller but slightly less full-featured package built from source.

5. Maintaining a .pet package repository containing prebuilt packages is not an option.

To build a package from source during 3builddistro and include it in the build:

1. Add a directory for your package under `woof-code/rootfs-petbuilds`.

2. Add a `petbuild` file under the directory: this is a shell script that defines two functions, `download()` and `build()`. The former downloads files needed to build the package, like a source code tarball. The latter builds the package and installs it to /.

3. If needed, add extra sources files that cannot be downloaded, like Puppy-specific patches.

4. If needed, add extra files and directories that will be included in the package, like configuration files.

5. Add a `pet.specs` file under the directory: this file is needed so PPM recognizes this package as a pre-installed one.

6. Add a `sha256.sum` file under the directory: this file specifies the SHA256 checksum of all files downloaded by `download()`. If this file is missing, no verification of downloaded files is performed and this can lead to broken packages. Files not listed in `sha256.sum` are not verified.

For example, if the `download()` function of the busybox package downloads files named `busybox-1.35.0.tar.bz2` and `busybox-guess_fstype.patch`, the `sha256.sum` file for busybox can be generated using:

       cd woof-code/rootfs-petbuilds/busybox
       . ./petbuild
       download
       sha256sum busybox-1.35.0.tar.bz2 busybox-guess_fstype.patch > sha256.sum

7. If needed, add a `pinstall.sh` post-installation script.

8. Add the package name to PETBUILDS, under `_00build.conf`.

# TECHNICAL NOTES

## History

Woof-CE (woof-Community Edition) is  a fork of Barry Kauler's woof2 fossil repository of Nov 11, 2013 commit f6332edbc4a75c262a8fec6e7d39229b0acf32cd.

## packages-templates directory

any directory in the template, the files in the target pkg will be cut down to the same selection (even if empty dir). Exception, file named `PLUSEXTRAFILES` then target will have all files from deb.

- 0-size file, means get file of same name from deb (even if in different dir) to target.
- Non-zero file, means copy this file from template to target.
- Template files with `-FULL` suffix, rename target file also (exs: in coreutils, util-linux).
  
Any dir in template with `PKGVERSION` in name, substitute actual pkg version number in target dir. Except for /dev, /var, all dirs in target are deleted to only those in template, except if file `PLUSEXTRADIRS` is found in template.
  
As a last resort, if target pkg is wrong, a file `FIXUPHACK` is a script that can be at top dir in template. It executes in target, with current-dir set to where `FIXUPHACK` is located. (ex: perl_tiny). Ran into problem slackware post-install scripts messing things up. See near bottom of '2createpackages' how damage is limited. Also `DISABLE_POST_INSTALL_SCRIPT=yes` in `FIXUPHACK` to disable entirely.
  
If a dir in template has files in it then target is cut down (unless `PLUSEXTRAFILES` present), however there are some exceptions (such as .so regular files).

## Packages-puppy-*

Notice that there are `Packages-puppy-noarch-official`, also `Packages-puppy-common-official`

The single-digit `-2-`, `-3-`, `-4-`, `-5-` files reside on ibiblio.org also. These files list the complete contents of each repository.

## Puppy filenames

The main Puppy files are:

    vmlinuz, initrd.gz, puppy.sfs, zdrv.sfs, fdrv.sfs, adrv.sfs, ydrv.sfs

Versioning is put into the last two, for example:

    vmlinuz, initrd.gz, puppy_slacko_7.0.0, zdrv_slacko_7.0.0.sfs fdrv_slacko_7.0.0.sfs, adrv_slacko_7.0.0.sfs, ydrv_slacko_7.0.0.sfs

...those last two names are intended to be unique for that build of Puppy, so they can be found at bootup.

## DISTRO_SPECS file

The filenames are stored in the built Puppy, in /etc/DISTRO_SPECS.
For example:

    DISTRO_PUPPYSFS='puppy_slacko_7.0.0.sfs'
    DISTRO_ZDRVSFS='zdrv_slacko_7.0.0.sfs'
    DISTRO_FDRVSFS='fdrv_slacko_7.0.0.sfs'
    DISTRO_ADRVSFS='adrv_slacko_7.0.0.sfs'
    DISTRO_YDRVSFS='ydrv_slacko_7.0.0.sfs'

So, any script that wants to know what the names are can read these variables.

Woof 3builddistro also copies DISTRO_SPECS into the initrd.gz, so that the `init` script can see what files to search for.

However, in a running Puppy, you can find out the filenames in the way that scripts have done before, by reading `PUPSFS` and `ZDRV` variables in /etc/rc.d/PUPSTATE.

In fact, to clarify the difference between these two sets of variables,
I have put this comment into /etc/DISTRO_SPECS:

    #Note, the .sfs files below are what the `init` script in initrd.gz searches for,
    #for the partition, path and actual files loaded, see `PUPSFS` and `ZDRV` in /etc/rc.d/PUPSTATE

# by 01micko

Woof-CE, a fork of woof2 can build the same as woof2 however a new feature has been added as of today. It now has the ability to build a distro with out modules in the initrd.gz, a feature which had been pioneered by Fatdog  developers kirk and jamesbond. This has a number of advantages over the  legacy kernel builds.
1. No messy copying kernel modules from the initial ram disk to the root system.
2. Ease of changing kernels.

I have named this the 'huge' type kernel, for want of a better term. The rationale for this is that Slackware developers name their default kernel `huge-$some_suffix`. The reason is that the vmlinuz kernel image contains all the necessary filesystem and hardware drivers to get the system to boot and hand over to the real running system. Once that occurs, kernel modules are loaded to bring up the rest of the hardware and extra filesystems if necessary.

"kernel-kit", part of woof-CE, has the ability to produce one of these 'huge' style kernel packages. Please read the relevant  README and the comments in "build.conf" inside the kernel-kit directory.

If you have built a "huge" style kernel with kernel-kit then place the package in the "huge_kernel" directory at the root of your woof installation. If not, one will be downloaded for you after you invoke 3builddistro from the CLI. You do get a choice of which version you want. Be sure you choose the correct architecure. All 32 bit builds are suffixed with either  i486, i686 or x86. All 64 bit builds are suffixed x86_64. At the end you will end up with an ISO image, devx and checksums as usual.

Regards,
Barry Kauler
puppylinux.com
