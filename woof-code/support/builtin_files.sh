#!/bin/bash
# * called by 3builddistro
# * we're in ./sandbox3 or .
# * processing happens in ./sandbox3

#===== need to get build info =====
if [ ! -f _00build.conf ] ; then
	cd ..
fi
. ./_00build.conf
. ./_00func
. ./DISTRO_SPECS
source_compat_repos
source_pkgs_specs
set_binaries_var
set_archdir_var
cd sandbox3 || exit 1
#==================================

TDIR="rootfs-complete"

if [ "$1" = "dev" -a -d devx ] ; then
	DEVXP='_DEV'
	TDIR='devx'
fi

#======================================================================================

#100527 build a .pet with lists of all builtin files...
echo
echo "Now building sandbox3/0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}.pet,"
echo "which is a PET package with lists of all packages and files builtin to the SFS..."
rm   -rf 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION} 2>/dev/null
mkdir -p 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}/root/.packages/builtin_files
mkdir -p /tmp/0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}

for ONEGENDIR in $(find -H ../packages-${DISTRO_FILE_PREFIX} -maxdepth 1 -type d | sort)
do
	ONEGENNAME=${ONEGENDIR##*/} #basename $ONEGENDIR
	if ! ( echo "$PKGS_SPECS_TABLE" | grep -q "^yes|${ONEGENNAME}|" ) ; then
		continue
	fi
	if [ "${DEVXP}" ] ; then
		if [ -d ../packages-${DISTRO_FILE_PREFIX}/${ONEGENNAME}_DEV ] ; then
			ONEGENNAME=${ONEGENNAME}_DEV
			ONEGENDIR=${ONEGENDIR}_DEV
		else
			continue
		fi
	fi
	echo -n "$ONEGENNAME "
	#          ignore top-level files
	find -H $ONEGENDIR -mindepth 2 \( -type f -o -type l \) 2>/dev/null | \
		sed -e "s%^../packages-${DISTRO_FILE_PREFIX}/${ONEGENNAME}/%/%" | \
			sort > /tmp/0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}/${ONEGENNAME}.files
	sync
	(
	while read ONELINE ; do
		if [ -e "${TDIR}${ONELINE}" ];then
			[ -d "${TDIR}${ONELINE}" ] && continue #ignore symlinks to directories
			echo "${ONELINE}" #only files that are in ${TDIR}
		fi
	done < /tmp/0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}/${ONEGENNAME}.files
	) > 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}/root/.packages/builtin_files/${ONEGENNAME}
done

# do the same for rootfs-packages.. does not apply to devx.
if [ ! "${DEVXP}" -a -f /tmp/rootfs-packages.specs ] ; then
	while read line
	do
		PKGL=`echo $line | cut -d '|'  -f 2`
		echo -n "${PKGL} "
		find -H ../rootfs-packages/$PKGL -mindepth 2 \( -type f -o -type l \) 2>/dev/null | \
			sed -e "s%^../rootfs-packages/${PKGL}/%/%" | \
			sort > /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${PKGL}.files
		sync
		mkdir -p 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/root/.packages/builtin_files
		while read ONELINE ; do
			if [ -e "${TDIR}${ONELINE}" ];then
				[ -d "${TDIR}${ONELINE}" ] && continue #a symlink to a directory
				echo "${ONELINE}" >> 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/root/.packages/builtin_files/${PKGL}
			fi
		done < /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${PKGL}.files
	done < /tmp/rootfs-packages.specs
	rm -f /tmp/rootfs-packages.specs
fi

echo
echo "0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}|0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}|${DISTRO_VERSION}||BuildingBlock|||0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}.pet||Lists of files built-in to the SFS file||||
" > 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}/pet.specs
rm -f 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}.pet 2>/dev/null

dir2tgz 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}
tgz2pet 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}.tar.gz
rm -rf /tmp/0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}
echo

mkdir -p ${TDIR}/root/.packages

echo "installing pkg lists into ${TDIR}/root/.packages/builtin_files..."
cp -a -f 0builtin_files_${DISTRO_FILE_PREFIX}${DEVXP}-${DISTRO_VERSION}/root/.packages/builtin_files \
			${TDIR}/root/.packages
echo '...done'

### END ###