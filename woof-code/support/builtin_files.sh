#!/bin/sh
# * sourced by 3builddistro
# * we're in sandbox3

if [ "$BUILDSYS" != "yes" ] ; then
	echo "* standalone *"
	cd ..
	. ./_00build.conf
	. ./_00func
	. ./DISTRO_SPECS
	source_compat_repos
	source_pkgs_specs
	set_binaries_var
	set_archdir_var
	cd sandbox3
fi

#======================================================================================

#100527 build a .pet with lists of all builtin files...
echo
echo "Now building sandbox3/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.pet,"
echo "which is a PET package with lists of all packages and files builtin to the SFS..."
rm -rf 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION} 2>/dev/null
mkdir 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}
mkdir -p /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}
for ONEGENDIR in $(find -H ../packages-${DISTRO_FILE_PREFIX} -maxdepth 1 -type d | sort)
do
	ONEGENNAME=${ONEGENDIR##*/} #basename $ONEGENDIR
	if ! ( echo "$PKGS_SPECS_TABLE" | grep -q "^yes|${ONEGENNAME}|" ) ; then
		continue
	fi
	echo -n "$ONEGENNAME "
	find -H $ONEGENDIR -type f -o -type l | \
		sed -e "s%^\\.\\./packages-${DISTRO_FILE_PREFIX}/${ONEGENNAME}/%/%" | \
		sort > /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${ONEGENNAME}.files
	sync
	mkdir -p 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files
	(
	while read ONELINE
	do
		NEWPATH=${ONELINE%/*} #dirname "$ONELINE"
		[ "${NEWPATH}" = "" ] && continue #ignore top-level files.
		if [ -e "rootfs-complete${ONELINE}" ];then
			[ -d "rootfs-complete${ONELINE}" ] && continue #a symlink to a directory
			echo "${ONELINE}" #only files that are in rootfs-complete
		fi
	done < /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${ONEGENNAME}.files
	) > 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files/${ONEGENNAME}
done

# do the same for rootfs-packages
if [ -f /tmp/rootfs-packages.specs ];then
	while read line
	do
		PKGL=`echo $line | cut -d '|'  -f 2`
		echo -n "${PKGL} "
		find -H ../rootfs-packages/$PKGL -type f -o -type l | \
			sed -e "s%^\\.\\./rootfs-packages/${PKGL}/%/%" | \
			sort > /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${PKGL}.files
		sync
		mkdir -p 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files
		while read ONELINE
		do
			case "$ONELINE" in .*) continue ;; esac #catch ex: ../packages-qrky/abiword
			NEWPATH=${ONELINE%/*} #dirname "$ONELINE"
			[ "${NEWPATH}" = "" ] && continue #ignore top-level files.
			if [ -e "rootfs-complete${ONELINE}" ];then
				[ -d "rootfs-complete${ONELINE}" ] && continue #a symlink to a directory
				echo "${ONELINE}" >> 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files/${PKGL}
			fi
		done < /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${PKGL}.files
	done < /tmp/rootfs-packages.specs
	rm -f /tmp/rootfs-packages.specs
fi
echo
echo "0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}|0builtin_files_${DISTRO_FILE_PREFIX}|${DISTRO_VERSION}||BuildingBlock|||0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.pet||Lists of files built-in to the SFS file||||
" > 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/pet.specs
rm -f 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.pet 2>/dev/null

dir2tgz 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}
tgz2pet 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.tar.gz
rm -rf /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}
echo
echo "installing pkg lists into rootfs-complete${PACKAGES_DIR}/builtin_files..."
cp -a -f 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files \
	rootfs-complete${PACKAGES_DIR}
echo '...done'

### END ###