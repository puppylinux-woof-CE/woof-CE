# Pkg

a command line package manager

## Features:

- powerful command line interface, lots of options
- supports packages: .pet, tar.gz, .txz, .deb, .sfs
- context-sensitive TAB completion of package, file, dir and repo names
- automatically find best matching packages or let the user choose
- search for packages in individual or all repos
- easily add more repos, direct from Ubuntu, PPA, Debian & Slackware sources
- easily compile packages from source (supports petbuild, src2pkg, sbopkg, buildpet)
- combine packages and dependencies into SFS files
- convert packages between supported filetypes
- find out which package a file belongs to
- find out which repo a package belongs to
- compatible with Puppy Package Manager
- includes a console frontend (dialog) menu, called Pkgdialog
- includes a GTK frontend (GTKdialog), called Gpkgdialog

### Dependencies

- Bash & Busybox (ash, wget, find, which, grep, sed, tar, du, sync, etc)
- coreutils (cp, mv, rm, wc, uniq, chmod, cut, cat, sort, etc)
- Puppy Package Manager (for `pkg repo-update` only)

### Quick Start

Install Pkg:

- clone this repo: `cd ~; mkdir -pv Gitlab; git clone https://gitlab.com/sc0ttj/Pkg Gitlab/Pkg`
- install (and register with PetGet): `cd ~/Gitlab/Pkg; ./installer.sh`

Get started:

1. View useful welcome message: `pkg welcome`
2. Update all repo files: `pkg update-sources`
3. List available repos: `pkg repo-list`
4. Change repo: `pkg repo <REPONAME>`
5. Search current repo for packages by name: `pkg n <PKGNAME>`
6. Search ALL repos for package name: `pkg na <PKGNAME>`
7. Get package info: `pkg status <PKGNAME>`
8. Download and install a package (and its dependencies): `pkg add <PKGNAME>`
9. Remove a package (and any left-over dependencies): `pkg rm <PKGNAME>`

##

### More advanced usage

Search all package info in a repo:

`pkg search WORDS`

Search all package info in all repos:

`pkg search-all WORDS`

Choose from a selection of matching packages, and decide which
ones to download, install, which dependencies to get, as you go:

`pkg --ask add "firefox mplayer"`

Download a package, plus its dependencies, but don't install:

`pkg get-only PKGNAME`

Or manually download and install packages without dependencies:

`pkg download PKGNAME; pkg install PKGNAME`

Ask to uninstall each '\_DEV' package you have installed:

`pkg list-installed | grep _DEV | pkg --ask uninstall -`

Display busybox package status, and package contents:

`pkg ps busybox -c busybox`

Download and unzip all repo packages matching 'freeciv':

`cd /root/pkg; pkg na freeciv | pkg d -; pkg ld freeciv | pkg unpack -`

Build (compile) packages from source:

`pkg build emelfm`

Build (compile) packages from source, with custom build options:  
(requires BUILDTOOL=buildpet in ~/.pkg/pkgrc)

`pkg build xarchiver --configure='--prefix=/usr/local --other-opts' --cflags='-D -02 -whatever'`

Set a different config file:

`PKGRC=/path/to/your/pkgrc <pkg command>`

Let Pkg suggest packages on missing commands:

`source /usr/share/pkg/command_not_found_handle.sh`

Disable package suggestions on missing command with:

`unset command_not_found_handle`

## Environment Variables:

```
 HIDE_INSTALLED [=false]  if true, ignore/hide installed packages
 HIDE_BUILTINS  [=true]   if true, ignore/hide builtin packages
 HIDE_USER_PKGS [=true]   if true, ignore/hide user installed packages
 NO_ALIASES   [=false]    if true, ignore package name aliases in searches
 NO_INSTALL   [=false]    if true, skip installing of packages
 PKG_NO_COLOURS [=false]  if true, disable coloured output
```

When BUILDTOOL=buildpet in ~/.pkg/pkgrc (use with `pkg build` command):

```
 PKG_CONFIGURE  [='']       custom configure options fpr building packages
 PKG_CFLAGS   [='']       custom CFLAG options for buiding packages
```

## Config files used:

```
# These config files get copied to ~/.pkg/ on first run.

/etc/pkg/pkgrc		# the Pkg rc file (config file)
/etc/pkg/sources	# the database of all supported (installed) repositories
/etc/pkg/sources-all	# the database of all available repos

# NOT INCLUDED in Pkg:

/root/.packages/Packages-*			# the repo files
/root/.packages/user-installed-packages		# user installed packages
/root/.packages/woof-installed-packages		# built-in packages
/root/.packages/devx-installed-packages		# built-in devx packages
/root/.packages/<pkgname>.files			# package file lists
```

##

### Example /etc/pkg/pkgrc

```
# where local pkgs are downloaded, built, etc
WORKDIR=/root/pkg
# current repo details
REPONAME=slacko14.2
EX=pet
REPOFILE=Packages-puppy-slacko14.2-official
REPOURL1=http://distro.ibiblio.org/puppylinux/pet_packages-slacko14.2/
REPOURL2=http://ftp.nluug.nl/os/Linux/distr/puppylinux/pet_packages-slacko14.2/
REPOURL3=
REPOURL4=
# internal settings, see --repo-pkg-scope, --repo-dep-scope
PKGSEARCH="pkg -n"
PKGSEARCHEXACT="pkg -ne"
DEPSEARCH="pkg -na"
DEPSEARCHEXACT="pkg -nea"
# other repos to check after current repo (in the order below)
REPOFALLBACKS="slackware14.2 slackware14.2-salix slackware14.2-extra slacko14.1 slacko14 slacko noarch common wary53x wary51x akita dpup quirky puppy4 puppy3 puppy2"
# other settings
PKGSCOPE="one"		# search pkgs in current or all repos
DEPSCOPE="all"		# search deps of PKG in current or all repos
BLEDGE="no"		# always get latest pkg versions (ignore fallback list)
RDCHECK="yes"		# recursive dep check
BUILDTOOL=petbuild	# the tools used for compiling pkgs (petbuild|buildpet|src2pkg|sbopkg)
```

##

### Example /etc/pkg/sources-all:

Syntax:

`repo_name|pkg_ext|repo_filename|url1|url2|url3|url4|fallback_list`

Description:

- repo_name - the name of the repository
- pkg_ext - the file extension of the packages in the repo
- repo_filename - the file name of the repository (in /root/.packages)
- url1 - the URL of the repository, where the packages live
- url2 - additional mirror of the repository (optional)
- url3 - additional mirror of the repository (optional)
- url4 - additional mirror of the repository (optional)
- fallback_list - a list of repos to search if pkg not in current repo

Example:

```
# some Puppy repos
noarch|pet|Packages-puppy-noarch-official|http://ftp.nluug.nl/os/Linux/distr/puppylinux/pet_packages-noarch/|http://distro.ibiblio.org/puppylinux/pet_packages-noarch/|||common quirky wary53x wary51x lucid dpup akita puppy5 puppy4 puppy3 puppy2 slacko slacko14

common|pet|Packages-puppy-common-official|http://ftp.nluug.nl/os/Linux/distr/puppylinux/pet_packages-common/|http://distro.ibiblio.org/puppylinux/pet_packages-common/|||noarch quirky wary53x wary51x lucid dpup akita puppy5 puppy4 puppy3 puppy2 slacko slacko14 saluki

# some Slackware 14.2 repos
slacko14.2|pet|Packages-puppy-slacko14.2-official|http://distro.ibiblio.org/puppylinux/pet_packages-slacko14.2/|http://ftp.nluug.nl/os/Linux/distr/puppylinux/pet_packages-slacko14.2/|||slackware14.2 slackware14.2-salix slackware14.2-extra slacko14.1 slacko14 slacko noarch common wary53x wary51x akita dpup quirky puppy4 puppy3 puppy2

slackware14.2|txz|Packages-slackware-14.2-official|http://slackware.cs.utah.edu/pub/slackware/slackware-14.2/|http://slackware.mirrors.tds.net/pub/slackware/slackware-14.2/|http://ftp.gwdg.de/pub/linux/slackware/slackware-14.2/|http://ftp.isu.edu.tw/pub/Linux/Slackware/slackware-14.2/|slackware-14.2 slackware-14.2-extra slackware14.2-salix slacko14.2 slackware14.1 slackware14.1-patches slackware14.1-slacky slackware14.1-salix slacko14.1 slacko14 slacko noarch common wary53x wary51x akita quirky puppy4 puppy3 puppy2

slackware14.2-extra|txz|Packages-slackware-14.2-extra|http://ftp.nluug.nl/pub/os/Linux/distr/salix/${DBIN_ARCH}/extra-${DISTRO_COMPAT_VERSION}/|http://slackware.uk/salix/${DBIN_ARCH}/extra-${DISTRO_COMPAT_VERSION}/|http://www.gtlib.gatech.edu/pub/salixos/${DBIN_ARCH}/extra-${DISTRO_COMPAT_VERSION}/||slacko14.2 slackware14.2 slackware14.2-salix slackware14.1 slackware14.1-patches slackware14.1-slacky slackware14.1-salix slacko14.1 slacko14 slacko noarch common wary53x wary51x akita quirky puppy4 puppy3 puppy2

# some Ubuntu Raring repos
raring|pet|Packages-puppy-raring-official|http://ftp.nluug.nl/os/Linux/distr/puppylinux/pet_packages-xenial64/|http://distro.ibiblio.org/puppylinux/pet_packages-raring/|||noarch common wary53x wary51x quirky puppy5 puppy4

raring-main|deb|Packages-ubuntu-raring-main|http://ftp.filearena.net/pub/ubuntu/ubuntu/||||raring raring-universe noarch common wary53x wary51x puppy5 puppy4

raring-universe|deb|Packages-ubuntu-raring-universe|http://ftp.filearena.net/pub/ubuntu/ubuntu/||||raring raring-main raring-multiverse noarch common wary53x wary51x puppy5 puppy4
```

The `sources` file is generated from `sources-all` using the command:

```
pkg --update-sources`
```

##

### All Options:

```
============================================================
Pkg - a command-line package manager
============================================================

Usage: ${bold}pkg [OPTION(S)] COMMAND SEARCH|PKGNAME|BUILDSCRIPT|FILE|-${endcolour}

OPTIONS:

These options can be used together and MUST precede all others:

 --ask|-a                   ask before doing stuff (give as 1st option)
 --quiet|-q                 suppress some output, like download progress
 --force |-f                force downloading, installing and uninstalling
 --no-colour|-nc            disable ANSI colours in $SELF output

COMMANDS:

The commaands below can be used with the options above, but they can't be
used with each other:

  search|s [SEARCH]          search all package info in CURRENT repo
  search-all|sa [SEARCH]     search all package info in ALL repos

  names|n [PKGNAME]          list package name matches in the CURRENT repo
  names-all|na [PKGNAME]     list package name matches in ALL repos

  add|a PKGNAME              download & install matching package and deps
  remove|rm PKGNAME          uninstall a package and any left over deps

  get|g PKGNAME              alias of add (see the command above)
  get-only|go PKGNAME        same as get, but don't install
  download|d PKGNAME         download a package from CURRENT repo
  install|i PKGNAME          install a downloaded package
  install-all|ia             install all downloaded packages
  update|pu [PKGNAME]        update all matching installed packages
  extract|unpack PKGFILE     extract package contents into folder
  split PKGFILE              split a package into DEV, DOC, NLS packages

  deps|e PKGNAME             install dependencies of matching package
  deps-download|ed PKGNAME   only download dependencies, no install
  deps-all|ea                install dependencies of all installed packages
  deps-check|ldd             prints message about missing dependencies

  uninstall|u PKGNAME        uninstall a package
  uninstall-all|ua           uninstall all installed packages
  delete|l PKGNAME           delete a downloaded package
  delete-all|la              delete ALL downloaded packages
  clean [PKGNAME]            delete downloaded pkg files of installed pkgs
  autoclean [yes|no]         auto delete pkg files after download+install

  list-downloaded|ld [PKG]   list downloaded packages, PKGNAME is a filter
  list-installed|li|LI [PKG] list installed packages, PKGNAME is a filter
  list-deps|le|LE PKGNAME    list the dependencies of PKGNAME

  build-list|pbl [PKG]       list all build scripts, PKGNAME is optional
  build|pb PKG               build a PET package from source and install it
  pkg-combine|pc PKG         build a new package containing PKGNAME + deps
  sfs-combine|sc PKG         build a new SFS file containing PKGNAME + deps
  repack|pr PKG              build a .pet package from an installed package
  merge PKGNAME,PKGNAME,..   merge multiple packages into a single package

  status|ps|PS PKG           show package status (name, size, deps, etc)
  contents|c PKG             list the contents of a downloaded package
  entry|pe PKG               show package repo entry (if in current repo)
  installed|pi PKG           return true if package installed, false if not

  all-pkgs                   list details of all packages in CURRENT repo
  names-exact|ne [PKG]       list EXACT package name matches in CURRENT repo
  names-exact-all|nea [PKG]  list EXACT package name matches in ALL repos

  what-needs|wn PKGNAME      lists pkgs that depend on PKGNAME
  which|w FILENAME           find out which pkg FILENAME comes from
  which-repo|wr PKG          find out which repo PKG comes from

  repo|r [REPONAME]          set repo to use, show current repo if none given
  repo-info|ri REPONAME      display the name, and other info of CURRENT repo
  repo-update|ru [REPONAME]  update the current repo package list
  repo-list|rl               list names of all available repositories
  repo-file-list|rfl         list all available repository files
  repo-convert|rc FILE       convert repo files to pre/post Woof format

  add-repo                   add a Pkg, PPA, Ubuntu, Debian or Slackware repo
  rm-repo                    remove a user-installed repo
  dir2repo                   create a Puppy repo from a directory of packages
  add-source                 add a Puppy repo (needs repo file in ~/.packages/)
  update-sources             update the list of available repos

  repo-pkg-scope one|all     search pkgs in current repo (one), or all (all)
  repo-dep-scope one|all     search deps in current repo (one), or all (all)
  bleeding-edge no|yes       if yes, get latest pkg versions, from ANY repo
  rdep-check no|yes          get deps recursively (yes), or not (no)

  dir2pet DIR                create a pet package from a directory
  dir2sfs DIR                create an sfs package from a directory
  dir2tgz DIR                create a tar.gz file from a directory
  deb2pet DEBFILE            convert local deb file to a pet package
  pet2sfs PETFILE            convert local pet file to an sfs package
  pet2tgz PETFILE            convert local pet file to a tar.gz package
  pet2txz PETFILE            convert local pet file to a tar.xz package
  sfs2pet SFSFILE            convert local sfs file to a pet package
  tgz2pet TARFILE            convert local tar.gz|tgz file to PET
  txz2pet TXZFILE            convert local tar.xz|txz file to PET

  welcome                    print some useful cmds to help get started
  show-config                show current config, repo and search settings
  workdir                    set a new working directory. Default is ~/pkg/

  version|v                  show the version of this script

  help|h                     show this help information
  help-all|H                 show a full description, with added info
  usage [CMD]                show usage of CMD, or list available cmds
  examples|ex                show example command line usage of $SELF
  func-list                  list all functions used in this program
```

##

### Example Commands:

```
 pkg s SEARCH			# list pkgs in current repo matching SEARCH

 pkg sa SEARCH			# list pkgs in all repos matching SEARCH

 pkg n SEARCH			# search name only, list all matching pkgs

 pkg add blender    # install Blender and it dependencies

 pkg rm blender     # remove Blender and any left-over dependencies

 pkg la			      # ask to delete all downloaded packages

 pkg -a e PKGNAME		# install deps of PKGNAME, ask each time

 pkg -a d qupzilla-1.2.0	# ask to download qupzilla-1.2.0

 pkg go filezilla		# download filezilla & deps, don't install

 pkg e PKGNAME			# install all deps of PKGNAME, dont ask

 pkg d qupzilla-1.3.1		# download qupzilla-1.3.1 no questions

 pkg l qupzilla-1.3.1		# delete the downloaded qupzilla-1.3.1

 pkg build jwm	    	# compile, build & install the 'jwm' package

 pkg la		        	# delete all downloaded packages without asking

 pkg li vim | pkg status -	# Get info on all installed Vim pkgs

 pkg li vim | pkg wr -	# Get repo of an installed Vim pkg

 pkg li | pkg -a u -		# Ask to uninstall installed pkgs one by one

 pkg dir2sfs /path/to/dir/	# convert a local dir to a .sfs package

 pkg i /path/to/file.pet	# install PET, include the extension!

 pkg tgz2pet /path/to/file	# convert a local .tar.gz file to PET

 pkg unpack /path/to/file	# extract the given package file
```

##

### How it works

Pkg searches repo files for the given package name(s).

If no exact package name was given, package can offer a choice.

If `--ask` was given, users must choose from the on screen options.

When a package name is given, `--get` can automatically find the
best match.

It can then download it, install it, and also its dependencies.

Most other options (`--download, --install`) need an exact package name.
