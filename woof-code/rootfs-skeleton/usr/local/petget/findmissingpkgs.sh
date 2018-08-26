#!/bin/sh
#(c) Copyright Barry Kauler 2009, puppylinux.com
#2009 Lesser GPL licence v2 (see /usr/share/doc/legal).
#called from /usr/local/petget/installpreview.sh or check_deps.sh
#/tmp/petget_pkg_name_aliases_patterns is written by pkg_chooser.sh.
#passed param is a list of dependencies (DB_dependencies field of the pkg database).
#results format, see comment end of this script.
#100126 handle PKG_NAME_IGNORE variable from file PKGS_MANAGEMENT.
#100711 fix handling of PKG_NAME_ALIASES variable (defined in PKGS_MANAGEMENT file).
#110706 finding missing dependencies fix (running mageia 1).
#110722 versioning info added to dependencies.
#110822 versioning operators can be chained, ex: +linux_kernel&ge2.6.32&lt2.6.33
#120822 in precise puppy have a pet 'cups' instead of the ubuntu debs. the latter are various pkgs, including 'libcups2'. we don't want libcups2 showing up as a missing dependency, so have to screen these alternative names out. see also pkg_chooser.sh
#120904 bugfix, was very slow.

DB_dependencies="$1" #in standard format of the package database, field 9.

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS #has PKGS_SPECS_TABLE
. /root/.packages/PKGS_MANAGEMENT #has PKG_ALIASES_INSTALLED

#110722 versioning info added to dependencies...
#the dependencies field can now have &ge, &gt, &eq, &le, &lt
#ex1: |+ncurses,+readline&ge2.3.5,+glibc|
#chained operators allowed: ex2: |+ncurses,+readline&ge2.3.5&lt2.3.6,+glibc|
#if you want a package to be kernel version sensitive:
#ex3: |+ncurses,+readline,+glibc,+linux_kernel&ge2.6.39|

#make pkg deps into patterns...
( #> /tmp/petget_pkg_deps_patterns
	#ex: DB_dependencies='+ncurses,+readline,+glibc,+linux_kernel&ge2.6.39'
	for i in ${DB_dependencies//,/ } #convert ',' to ' '
	do
		i=${i#+}      #remove leading '+'
		i="${i%%&*}"  #chop off any versioning info
		echo "|${i}|" #e.g.: |ncurses|
	done
) > /tmp/petget_pkg_deps_patterns

#same as above, but with versioning info...
( #> /tmp/petget_pkg_deps_patterns_with_versioning
	for i in ${DB_dependencies//,/ } #convert ',' to ' '
	do
		i=${i#+}       #remove leading '+'
		i="${i//&/|}"  #convert '&' to '|'
		echo "|${i}|"  #e.g.: |linux_kernel|ge2.6.39|
	done
) > /tmp/petget_pkg_deps_patterns_with_versioning

#110706 mageia, a dep "libdbus-glib-1_2" must be located in variable PKG_ALIASES_INSTALLED (in file PKGS_MANAGEMENT)...
#/tmp/petget_pkg_name_aliases_patterns[_raw] created in check_deps.sh
for ONEALIAS in `cat /tmp/petget_pkg_name_aliases_patterns_raw | tr '\n' ' ' | tr ',' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 FNDDEPSPTNS="`grep "$ONEALIAS" /tmp/petget_pkg_deps_patterns`"
 if [ "$FNDDEPSPTNS" != "" ];then
  echo "$FNDDEPSPTNS" >> /tmp/petget_pkg_name_aliases_patterns
 fi
done

#need patterns of all installed pkgs...
#100711 /tmp/petget_installed_patterns_system is created in pkg_chooser.sh.
cp -f /tmp/petget_installed_patterns_system /tmp/petget_installed_patterns_all
if [ -s /root/.packages/user-installed-packages ];then
 INSTALLED_PATTERNS_USER="`cat /root/.packages/user-installed-packages | cut -f 2 -d '|' | sed -e 's%^%|%' -e 's%$%|%' -e 's%\\-%\\\\-%g'`"
 echo "$INSTALLED_PATTERNS_USER" >> /tmp/petget_installed_patterns_all
 #120822 this code also in pkg_chooser.sh, find alt deb names...
 case $DISTRO_BINARY_COMPAT in
  ubuntu|debian|devuan|raspbian)
   #120904 bugfix, was very slow...
   MODIF1=`stat -c %Y /root/.packages/user-installed-packages` #seconds since epoch.
   MODIF2=0
   [ -f /var/local/petget/installed_alt_ptns_pet_user ] && MODIF2=`stat -c %Y /var/local/petget/installed_alt_ptns_pet_user`
   if [ $MODIF1 -gt $MODIF2 ];then
    INSTALLED_PTNS_PET="$(grep '\.pet|' /root/.packages/user-installed-packages | cut -f 2 -d '|')"
    if [ "$INSTALLED_PTNS_PET" != "" ];then
     xINSTALLED_PTNS_PET="$(echo "$INSTALLED_PTNS_PET" | sed -e 's%^%/%' -e 's%$%|%' -e 's%\-%\\-%g')"
     echo "$xINSTALLED_PTNS_PET" > /tmp/petget/fmp_xipp
     INSTALLED_ALT_NAMES="$(grep --no-filename -f /tmp/petget/fmp_xipp /root/.packages/Packages-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}-* | cut -f 2 -d '|')"
     if [ "$INSTALLED_ALT_NAMES" ];then
      INSTALLED_ALT_PTNS="$(echo "$INSTALLED_ALT_NAMES" | sed -e 's%^%|%' -e 's%$%|%' -e 's%\-%\\-%g')"
      echo "$INSTALLED_ALT_PTNS" > /var/local/petget/installed_alt_ptns_pet_user
      echo "$INSTALLED_ALT_PTNS" >> /tmp/petget_installed_patterns_all
     fi
    fi
    touch /var/local/petget/installed_alt_ptns_pet_user
   else
    cat /var/local/petget/installed_alt_ptns_pet_user >> /tmp/petget_installed_patterns_all
   fi
  ;;
 esac
fi

#add these alias names to the installed patterns...
#packages may have different names, add them to installed list...
INSTALLEDALIASES="`grep --file=/tmp/petget_installed_patterns_all /tmp/petget_pkg_name_aliases_patterns | tr ',' '\n'`"
[ "$INSTALLEDALIASES" ] && echo "$INSTALLEDALIASES" >> /tmp/petget_installed_patterns_all

#110706 mageia, a dep "libdbus-glib-1_2" must be located in variable PKG_ALIASES_INSTALLED (in file PKGS_MANAGEMENT)...
#/tmp/petget_pkg_name_aliases_patterns[_raw] created in check_deps.sh, pkg_chooser.sh
for ONEALIAS in `cat /tmp/petget_pkg_name_aliases_patterns_raw | tr '\n' ' ' | tr ',' ' '` #ex: |cxxlibs|,|glibc.*|,|libc\-.*|
do
 FNDPTN="`grep "$ONEALIAS" /tmp/petget_installed_patterns_all`"
 if [ "$FNDPTN" ];then
  FNDDEPPTN="`grep "$ONEALIAS" /tmp/petget_pkg_deps_patterns`"
  [ "$FNDDEPPTN" ] && echo "$FNDDEPPTN" >> /tmp/petget_installed_patterns_all
 fi
done

#100126 some names to ignore, as most likely already installed...
#/tmp/petget_pkg_name_ignore_patterns is created in pkg_choose.sh
cat /tmp/petget_pkg_name_ignore_patterns >> /tmp/petget_installed_patterns_all

#clean it up...
grep -v '^$' /tmp/petget_installed_patterns_all > /tmp/petget_installed_patterns_all-tmp
mv -f /tmp/petget_installed_patterns_all-tmp /tmp/petget_installed_patterns_all

#remove installed pkgs from the list of dependencies...
MISSINGDEPS_PATTERNS="`grep --file=/tmp/petget_installed_patterns_all -v /tmp/petget_pkg_deps_patterns | grep -v '^$'`"
echo "$MISSINGDEPS_PATTERNS" > /tmp/petget_missingpkgs_patterns #can be read by dependencies.sh, find_deps.sh.

#notes on results:
#/tmp/petget_missingpkgs_patterns has a list of missing dependencies, format ex:
#  |kdebase|
#  |kdelibs|
#  |mesa-lib|
#  |qt|
#/tmp/petget_installed_patterns_all (read in dependencies.sh) has a list of already installed
#  packages, both builtin and user-installed. One on each line, exs:
#  |915resolution|
#  |a52dec|
#  |absvolume_puppy|
#  |alsa\-lib|
#  |cyrus\-sasl|
#  ...notice the '-' are backslashed.

#110722
MISSINGDEPS_PATTERNS_WITHVER="`grep --file=/tmp/petget_missingpkgs_patterns /tmp/petget_pkg_deps_patterns_with_versioning | grep -v '^$'`"
echo "$MISSINGDEPS_PATTERNS_WITHVER" > /tmp/petget_missingpkgs_patterns_with_versioning #can be read by dependencies.sh, find_deps.sh.
#...ex each line: |kdebase|ge2.3.6|
# ex with chained operators: |kdebase|ge2.3.6|lt2.4.5|
#note, dependencies.sh currently not using this file.
#120831 npierce, jemimah: dependencies.sh now using /tmp/petget_missingpkgs_patterns_with_versioning.

###END###
