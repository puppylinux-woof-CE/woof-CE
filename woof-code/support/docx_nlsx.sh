#!/bin/sh
# * sourced by 3builddistro
# * we're in sandbox3

if [ ! "$BUILDSYS" ] ; then
	 #not being sourced - force build - testing
	. ../_00func
	. ../_00build.conf
	. ../DISTRO_SPECS
	BUILD_DOCX=yes
	BUILD_NLSX=yes
	DOCXSFS="docx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
	NLSXSFS="nlsx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
fi

if [ "$BUILD_DOCX" = "yes" -o "$BUILD_NLSX" = "yes" ] ; then
	INSTALLED_PKGS=$((echo "$PETBUILDS" | tr ' ' '\n'; cat ../status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} | \
cut -f 1 -d '|' | tr ':' '\n' | sed '/^$/d') | sort -u)
fi

if [ "$BUILD_DOCX" = "yes" ] ; then
	echo
	rm -rf docx ${DOCXSFS}
	mkdir -p docx
	echo "Building docx..."
	for i in $INSTALLED_PKGS
	do
		if [ -d ../packages-${DISTRO_FILE_PREFIX}/${i}_DOC ] ; then
			echo -n " ${i}"
			cp -a --remove-destination ../packages-${DISTRO_FILE_PREFIX}/${i}_DOC/* docx/
		fi
	done
	if [ -d bdrv_DOC ] ; then
		echo -n " bdrv_DOC"
		cp -a --remove-destination bdrv_DOC/* docx/
	fi
	echo
	rm -f docx/pet.specs
	find docx/usr/share/doc -iname 'changelog*.gz' -delete
	[ "$USR_SYMLINKS" = "yes" ] && usrmerge docx 0
	echo "Creating $DOCXSFS..."
	[ -d docx/root ] && busybox chmod 700 docx/root
	[ -d docx/home/spot ] && busybox chmod 700 docx/home/spot
	mksquashfs docx ${DOCXSFS} ${SFSCOMP}
fi

if [ "$BUILD_NLSX" = "yes" ] ; then
	echo
	rm -rf nlsx ${NLSXSFS}
	mkdir -p nlsx
	echo "Building nlsx..."
	for i in $INSTALLED_PKGS
	do
		if [ -d ../packages-${DISTRO_FILE_PREFIX}/${i}_NLS ] ; then
			echo -n " ${i}"
			cp -a --remove-destination ../packages-${DISTRO_FILE_PREFIX}/${i}_NLS/* nlsx/
		fi
	done
	if [ -d bdrv_NLS ] ; then
		echo -n " bdrv_NLS"
		cp -a --remove-destination bdrv_NLS/* nlsx/
	fi
	echo
	rm -f nlsx/pet.specs
	mkdir -p nlsx/var/local
	touch nlsx/var/local/nlsx_loaded
	[ "$USR_SYMLINKS" = "yes" ] && usrmerge nlsx 0
	echo "Creating $NLSXSFS..."
	[ -d nlsx/root ] && busybox chmod 700 nlsx/root
	[ -d nlsx/home/spot ] && busybox chmod 700 nlsx/home/spot
	mksquashfs nlsx ${NLSXSFS} ${SFSCOMP}
fi

echo

### END ###