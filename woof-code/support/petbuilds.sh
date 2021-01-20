if [ -z "$WOOF_CFLAGS"]; then
    case "$DISTRO_TARGETARCH" in
    arm) WOOF_CFLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard" ;;
    x86) WOOF_CFLAGS="-march=i486 -mtune=i686" ;;
    x86_64) WOOF_CFLAGS="-march=generic -mtune=generic" ;;
    esac
fi

[ -z "$WOOF_CXXFLAGS"] && WOOF_CXXFLAGS="$WOOF_CFLAGS"

HAVE_CCACHE=0
[ -e devx/usr/bin/ccache ] && HAVE_CCACHE=1

WOOF_CC=gcc
WOOF_CXX=g++
if [ $HAVE_CCACHE -eq 1 ]; then
    WOOF_CC="ccache gcc"
    WOOF_CXX="ccache g++"
fi

WOOF_CFLAGS="$WOOF_CFLAGS -Os -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants"
WOOF_CXXCFLAGS="$WOOF_CXXCFLAGS -Os -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants"
WOOF_LDFLAGS="$WOOF_LDFLAGS -Wl,--gc-sections -Wl,--sort-common -Wl,-s"

MAKEFLAGS=-j`nproc`

HAVE_ROOTFS=0
HAVE_BUSYBOX=0
HERE=`pwd`
PKGS=

# busybox must be first, so other petbuilds can use coreutils commands
for i in ../rootfs-petbuilds/busybox ../rootfs-petbuilds/*; do
    NAME=${i#../rootfs-petbuilds/}

    if grep -q "^yes|${NAME}|" ../DISTRO_PKGS_SPECS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION}; then
        echo "Skipping ${NAME}, using a package"
        continue
    fi

    HASH=`md5sum $i/petbuild | awk '{print $1}'`
    if [ ! -d "../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}" ]; then
        if [ $HAVE_ROOTFS -eq 0 ]; then
            echo "Preparing build environment"
            rm -rf petbuild-rootfs-complete
            cp -a rootfs-complete petbuild-rootfs-complete

            rm -f sh petbuild-rootfs-complete/bin/sh
            ln -s bash petbuild-rootfs-complete/bin/sh

            HAVE_ROOTFS=1
        fi

        if [ $HAVE_BUSYBOX -eq 0 -a "$NAME" != "busybox" ]; then
            if [ ! -f petbuild-rootfs-complete/bin/busybox ]; then
                if [ -f ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/busybox/bin/busybox ]; then # busybox petbuild
                    install -D -m 755 ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/busybox/bin/busybox petbuild-rootfs-complete/bin/busybox
                elif [ -f ../packages-${DISTRO_FILE_PREFIX}/busybox/bin/busybox ]; then # prebuilt busybox
                    install -D -m 755 ../packages-${DISTRO_FILE_PREFIX}/busybox/bin/busybox petbuild-rootfs-complete/bin/busybox
                elif [ "$NAME" != "busybox" ]; then
                    echo "No busybox in the build environment!"
                    exit 1
                fi
            fi
            ../support/busybox_symlinks.sh petbuild-rootfs-complete
            HAVE_BUSYBOX=1
        fi

        echo "Downloading ${NAME}"

        mkdir -p ../../local-repositories/sources/${NAME}
        cd ../../local-repositories/sources/${NAME}
        . ${HERE}/../rootfs-petbuilds/${NAME}/petbuild
        download
        if [ -f ${HERE}/../rootfs-petbuilds/${NAME}/sha256.sum ]; then
            sha256sum -c ${HERE}/../rootfs-petbuilds/${NAME}/sha256.sum || exit 1
        fi

        echo "Building ${NAME}"

        cd $HERE

        mkdir -p ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH} petbuild-rootfs-complete-${NAME}
        mount -t aufs -o br=../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}:devx:petbuild-rootfs-complete petbuild petbuild-rootfs-complete-${NAME}

        mkdir -p petbuild-rootfs-complete-${NAME}/proc petbuild-rootfs-complete-${NAME}/sys petbuild-rootfs-complete-${NAME}/dev petbuild-rootfs-complete-${NAME}/tmp
        [ $HAVE_CCACHE -eq 1 ] && mkdir -p petbuild-rootfs-complete-${NAME}/root/.ccache
        mount --bind /proc petbuild-rootfs-complete-${NAME}/proc
        mount --bind /sys petbuild-rootfs-complete-${NAME}/sys
        mount --bind /dev petbuild-rootfs-complete-${NAME}/dev
        mount -t tmpfs -o size=1G petbuild-tmp-${NAME} petbuild-rootfs-complete-${NAME}/tmp
        if [ $HAVE_CCACHE -eq 1 ]; then
            mkdir -p ../../local-repositories/${WOOF_TARGETARCH}/petbuilds-ccache-${NAME}
            mount --bind ../../local-repositories/${WOOF_TARGETARCH}/petbuilds-ccache-${NAME} petbuild-rootfs-complete-${NAME}/root/.ccache
        fi

        cp -a ../../local-repositories/sources/${NAME}/* petbuild-rootfs-complete-${NAME}/tmp/
        cp -a ../rootfs-petbuilds/${NAME}/* petbuild-rootfs-complete-${NAME}/tmp/
        CC="$WOOF_CC" CXX="$WOOF_CXX" CFLAGS="$WOOF_CFLAGS" CXXFLAGS="$WOOF_CXXFLAGS" LDFLAGS="$WOOF_LDFLAGS" MAKEFLAGS="$MAKEFLAGS" chroot petbuild-rootfs-complete-${NAME} sh -ec "cd /tmp && . ./petbuild && build"
        ret=$?
        [ $HAVE_CCACHE -eq 1 ] && umount -l petbuild-rootfs-complete-${NAME}/root/.ccache
        umount -l petbuild-rootfs-complete-${NAME}/tmp
        umount -l petbuild-rootfs-complete-${NAME}/dev
        umount -l petbuild-rootfs-complete-${NAME}/sys
        umount -l petbuild-rootfs-complete-${NAME}/proc
        umount -l petbuild-rootfs-complete-${NAME}
        rmdir petbuild-rootfs-complete-${NAME}

        if [ $ret -ne 0 ]; then
            echo "ERROR: failed to build ${NAME}"
            rm -rf ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}
            rm -rf petbuild-rootfs-complete
            exit 1
        fi

        [ $HAVE_CCACHE -eq 1 ] && rm -rf ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/root/.ccache
        rm -rf ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/tmp ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/etc/ssl ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/etc/resolv.conf ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/usr/share/man ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/usr/share/info ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/root/.wget-hsts ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/usr/share/icons/hicolor/icon-theme.cache
        rmdir ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/* 2>/dev/null
        find ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH} -name '.wh*' -delete
        find ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH} -name '.git*' -delete
        find ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH} -type l | while read LINK; do
            [ "`readlink $LINK`" = "/bin/busybox" ] && rm -f $LINK
        done

        find ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH} -type f | while read ELF; do
            strip --strip-all -R .note -R .comment ${ELF} 2>/dev/null
        done

        for EXTRAFILE in ../rootfs-petbuilds/${NAME}/*; do
            case "${EXTRAFILE##*/}" in
            petbuild|*.patch|sha256.sum|*-*|DOTconfig) ;;
            *) cp -a $EXTRAFILE ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/
            esac
        done
    fi

    rm -f ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}
    ln -s ${NAME}-${HASH} ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}

    PKGS="$PKGS $NAME"
done

[ $HAVE_ROOTFS -eq 1 ] && rm -rf petbuild-rootfs-complete

for NAME in $PKGS; do
    echo "Copying ${NAME}"

    rm -f rootfs-complete/pinstall.sh
    cp -a ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}/* rootfs-complete/

    if [ -f rootfs-complete/pinstall.sh ]; then
        echo >> /tmp/rootfs_pkgs_pinstall.sh
        cat rootfs-complete/pinstall.sh >> /tmp/rootfs_pkgs_pinstall.sh
        echo >> /tmp/rootfs_pkgs_pinstall.sh
        rm -f rootfs-complete/pinstall.sh
    fi

    cat ../rootfs-petbuilds/${NAME}/pet.specs >> /tmp/rootfs-petbuilds.specs
done