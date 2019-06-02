#!/bin/sh
# * sourced by 3builddistro
# * we're in sandbox3

if [ ! "$BUILDSYS" ] ; then
	 #not being sourced - force build
	. ../_00func
	. ../_00build.conf
	. ../DISTRO_SPECS
	BUILD_DOCX=yes
	BUILD_NLSX=yes
fi

DOCXSFS="docx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
NLSXSFS="nlsx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"

if [ "$BUILD_DOCX" != "yes" -a "$BUILD_NLSX" != "yes" ] ; then
	exit
fi

INSTALLED_PKGS=$(cat ../status/findpkgs_FINAL_PKGS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} | \
cut -f 1 -d '|' | tr ':' '\n' | sed '/^$/d' | sort -u)

if [ "$BUILD_DOCX" = "yes" ] ; then
	echo
	rm -rf docx ${DOCXSFS}
	mkdir -p docx
	echo "Building docx..."
	for i in $INSTALLED_PKGS
	do
		if [ -d ../packages-${DISTRO_FILE_PREFIX}/${i}_DOC ] ; then
			cp -a --remove-destination ../packages-${DISTRO_FILE_PREFIX}/${i}_DOC/* docx/
		fi
	done
	sync
	rm -f docx/pet.specs
	echo "Creating $DOCXSFS..."
	mksquashfs docx ${DOCXSFS} ${SFSCOMP}
fi

if [ "$BUILD_NLSX" = "yes" ] ; then
	echo
	rm -rf nlsx ${NLSXSFS}
	mkdir -p docx
	echo "Building nlsx..."
	for i in $INSTALLED_PKGS
	do
		if [ -d ../packages-${DISTRO_FILE_PREFIX}/${i}_NLS ] ; then
			cp -a --remove-destination ../packages-${DISTRO_FILE_PREFIX}/${i}_NLS/* nlsx/
		fi
	done
	sync
	rm -f nlsx/pet.specs
	echo "Creating $NLSXSFS..."
	mksquashfs nlsx ${NLSXSFS} ${SFSCOMP}
fi

echo

### END ###