if [ -z "$WOOF_CFLAGS"]; then
    case "$DISTRO_TARGETARCH" in
    arm) WOOF_CFLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard" ;;
    x86) WOOF_CFLAGS="-march=i486 -mtune=i686" ;;
    x86_64) WOOF_CFLAGS="-march=generic -mtune=generic" ;;
    esac
fi

[ -z "$WOOF_CXXFLAGS"] && WOOF_CXXFLAGS="$WOOF_CFLAGS"

WOOF_CC="/ccache gcc"
WOOF_CXX="/ccache g++""

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

    HASH=`cat ../DISTRO_PKGS_SPECS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} ../DISTRO_COMPAT_REPOS-${DISTRO_BINARY_COMPAT}-${DISTRO_COMPAT_VERSION} ../DISTRO_PET_REPOS $i/petbuild | md5sum | awk '{print $1}'`
    if [ ! -d "../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}" ]; then
        if [ $HAVE_ROOTFS -eq 0 ]; then
            echo "Preparing build environment"
            rm -rf petbuild-rootfs-complete
            cp -a rootfs-complete petbuild-rootfs-complete

            rm -f sh petbuild-rootfs-complete/bin/sh
            ln -s bash petbuild-rootfs-complete/bin/sh

            # to speed up compilation, we build a static, native ccache executable
            if [ ! -f ../../local-repositories/ccache/ccache ]; then
                mkdir -p ../../local-repositories/ccache
                wget -t 1 -T 15 -O ../../local-repositories/ccache/ccache-3.7.12.tar.xz https://github.com/ccache/ccache/releases/download/v3.7.12/ccache-3.7.12.tar.xz
                tar -xJf ../../local-repositories/ccache/ccache-3.7.12.tar.xz
                cd ccache-3.7.12
                CFLAGS=-O3 LDFLAGS="-static -Wl,-s" ./configure
                MAKEFLAGS="$MAKEFLAGS" make
                mv ccache ../../local-repositories/ccache/ccache
                cd ..
            fi
            install -m 755 ../../local-repositories/ccache/ccache petbuild-rootfs-complete/ccache

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

        if [ -d ../../local-repositories/sources/${NAME} ]; then
            rm -rf ../../local-repositories/sources/${NAME}/* 2>/dev/null
        else
            mkdir ../../local-repositories/sources/${NAME}
        fi
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
        mkdir -p petbuild-rootfs-complete-${NAME}/root/.ccache
        mount --bind /proc petbuild-rootfs-complete-${NAME}/proc
        mount --bind /sys petbuild-rootfs-complete-${NAME}/sys
        mount --bind /dev petbuild-rootfs-complete-${NAME}/dev
        mount -t tmpfs -o size=1G petbuild-tmp-${NAME} petbuild-rootfs-complete-${NAME}/tmp
        mkdir -p ../../local-repositories/${WOOF_TARGETARCH}/petbuilds-ccache-${NAME}
        mount --bind ../../local-repositories/${WOOF_TARGETARCH}/petbuilds-ccache-${NAME} petbuild-rootfs-complete-${NAME}/root/.ccache

        cp -a ../../local-repositories/sources/${NAME}/* petbuild-rootfs-complete-${NAME}/tmp/
        cp -a ../rootfs-petbuilds/${NAME}/* petbuild-rootfs-complete-${NAME}/tmp/
        CC="$WOOF_CC" CXX="$WOOF_CXX" CFLAGS="$WOOF_CFLAGS" CXXFLAGS="$WOOF_CXXFLAGS" LDFLAGS="$WOOF_LDFLAGS" MAKEFLAGS="$MAKEFLAGS" chroot petbuild-rootfs-complete-${NAME} sh -ec "cd /tmp && . ./petbuild && build"
        ret=$?
        umount -l petbuild-rootfs-complete-${NAME}/root/.ccache
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

        rm -rf ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-${HASH}/root/.ccache
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

    rm -f ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-latest
    ln -s ${NAME}-${HASH} ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-latest

    PKGS="$PKGS $NAME"
done

[ $HAVE_ROOTFS -eq 1 ] && rm -rf petbuild-rootfs-complete

for NAME in $PKGS; do
    echo "Copying ${NAME}"

    rm -f rootfs-complete/pinstall.sh
    cp -a ../../local-repositories/${WOOF_TARGETARCH}/petbuilds/${DISTRO_FILE_PREFIX}/${NAME}-latest/* rootfs-complete/

    if [ -f rootfs-complete/pinstall.sh ]; then
        echo >> /tmp/rootfs_pkgs_pinstall.sh
        cat rootfs-complete/pinstall.sh >> /tmp/rootfs_pkgs_pinstall.sh
        echo >> /tmp/rootfs_pkgs_pinstall.sh
        rm -f rootfs-complete/pinstall.sh
    fi

    cat ../rootfs-petbuilds/${NAME}/pet.specs >> /tmp/rootfs-petbuilds.specs
done