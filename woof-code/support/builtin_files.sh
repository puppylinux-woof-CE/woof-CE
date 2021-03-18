#!/bin/sh
# * sourced by 3builddistro
# * we're in sandbox3

. ../_00func
. ../DISTRO_SPECS

echo -e "\nNow building lists of all packages and files builtin to the SFS..."
rm -rf 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION} 2>/dev/null

mkdir 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}
mkdir -p /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}
mkdir -p 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files

cat ../status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} | sort | \
while IFS="|" read -r F1 F2 F3 F4 F5 ETC
do
	GENERICNAMES="$F1"
	NAMEONLY="$F5"
	case $NAMEONLY in *"_DOC"|*"_NLS"|*"_DEV") continue ;; esac
	for i in ${GENERICNAMES//:/ } ; do
		if [ -d ../packages-${DISTRO_FILE_PREFIX}/$i ] ; then
			if [ -f 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files/${i} ] ; then
				continue
			fi
			echo -n "$i "
			find -H ../packages-${DISTRO_FILE_PREFIX}/$i -type f -o -type l | \
				sed -e "s%^\\.\\./packages-${DISTRO_FILE_PREFIX}/${i}/%/%" | \
				sort > /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${i}.files
			sync
			(
			while read ONELINE ; do
				[ -e "rootfs-complete${ONELINE}" ] && echo "${ONELINE}" #only files that are in rootfs-complete
			done < /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${i}.files
			) > 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files/${i}
		fi
	done
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
		while read ONELINE ; do
			if [ -e "rootfs-complete${ONELINE}" ];then
				echo "${ONELINE}" >> 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files/${PKGL}
			fi
		done < /tmp/0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/${PKGL}.files
	done < /tmp/rootfs-packages.specs
	rm -f /tmp/rootfs-packages.specs
fi

echo
rm -f 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.tar.gz
tar -z -c -f 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}.tar.gz 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}/
echo
echo "installing pkg lists into rootfs-complete${PACKAGES_DIR}/builtin_files..."
cp -a -f 0builtin_files_${DISTRO_FILE_PREFIX}-${DISTRO_VERSION}${PACKAGES_DIR}/builtin_files \
	rootfs-complete${PACKAGES_DIR}
echo '...done'

### END ###