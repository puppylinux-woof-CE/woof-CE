#!/bin/sh

# GPL-V2 or later at your discretion
# (c) Mick Amadio, 2021 01micko@gmail.com, Gold Coast QLD, Australia

# this script depends on modinfo to get firmware version of modules
# in the target kernel. Installs correct version from external sources
# whch MAY be non-free, however *should* be redistributable as long as user is made aware

export LANG=C

TEMP=/tmp/fw$$
OUT=$TEMP/lib/firmware
mkdir -p $OUT
TOOLREPO=tools
REPO=sources/firmware_extra
mkdir -p $TOOLREPO
mkdir -p $REPO
FIRMWARE_INSTALL_DIR_XTRA=$OUT
CWD=`pwd`
save_dld=true # might make this configuarable later
SRC_FW_DIR=$OUT
fw_tmp_list_xtra=/tmp/firmware_extra.lst #.${kernel_version}
export TOOLREPO REPO save_dld FIRMWARE_INSTALL_DIR_XTRA OUT TEMP CWD

#### tools
download_func() {
	PKGURL=$1
	PKG=$2
	TGT=${TEMP}
	if [ "$save_dld" = "true" ];then
		[ -e "${REPO}/${PKG}" ] && cp -af ${REPO}/${PKG} ${TEMP} && return $? # bale here
		TGT=${REPO}
	fi
	[ -z "$3" ] && OPT="-P ${TGT}" || OPT="-O ${TGT}/${PKG}"
	wget ${PKGURL} ${OPT} || return 1
	[ ! -e "${TEMP}/${PKG}" ] && cp -af ${REPO}/${PKG} ${TEMP} || return 1
}

B43_URL='https://www.lwfinger.com/b43-firmware/broadcom-wl-6.30.163.46.tar.bz2'
B43_LEG_URL='https://downloads.openwrt.org/sources/wl_apsta-3.130.20.0.o'
FW_CUT_URL='https://bues.ch/b43/fwcutter/b43-fwcutter-018.tar.bz2'
IPW2100_URL='https://src.fedoraproject.org/repo/pkgs/ipw2100-firmware/ipw2100-fw-1.3.tgz/46aa75bcda1a00efa841f9707bbbd113/ipw2100-fw-1.3.tgz'
IPW2200_URL='https://src.fedoraproject.org/repo/pkgs/ipw2200-firmware/ipw2200-fw-3.1.tgz/eaba788643c7cc7483dd67ace70f6e99/ipw2200-fw-3.1.tgz'
LIC_URL="https://raw.githubusercontent.com/Algernon-01/rpi-patches/master/usr/share/doc/raspi3-firmware/copyright"

build_cutter() {
	download_func "$FW_CUT_URL" b43-fwcutter-018.tar.bz2
	tar xjf ${TEMP}/b43-fwcutter-018.tar.bz2 -C ${TEMP} || return 1
	(
	cd ${TEMP}/b43-fwcutter-018
	make || return 1
	mkdir -p $CWD/$TOOLREPO/cutter
	install -m 0755 b43-fwcutter $CWD/$TOOLREPO/cutter || return 1
	)
	echo "b43-fwcutter is now installed in $TOOLREPO."
	sleep 1
}

#### wireless firmwares
extract_b43() {
	download_func "$B43_URL" broadcom-wl-6.30.163.46.tar.bz2
	tar xf ${TEMP}/broadcom-wl-6.30.163.46.tar.bz2 -C ${TEMP} || return 1
	$CWD/$TOOLREPO/cutter/b43-fwcutter -w "$FIRMWARE_INSTALL_DIR_XTRA" ${TEMP}/broadcom-wl-6.30.163.46.wl_apsta.o
	curl $LIC_URL | sed -e '1,40d' -e '/debian/,$d' > $FIRMWARE_INSTALL_DIR_XTRA/LICENCE.broadcom-b43x
	echo "Broadcom licence is now in $FIRMWARE_INSTALL_DIR_XTRA/LICENCE.broadcom-b43x"
}

extract_legacy() {
	download_func "$B43_LEG_URL" wl_apsta-3.130.20.0.o
	$CWD/$TOOLREPO/cutter/b43-fwcutter -w "$FIRMWARE_INSTALL_DIR_XTRA" ${TEMP}/wl_apsta-3.130.20.0.o
}

b43_func() {
	[ -e  "$CWD/$TOOLREPO/cutter/b43-fwcutter" ] || build_cutter
	[ $? -ne 0 ] && return 1
	case $1 in
		new)extract_b43 || return 1;;
		old)extract_legacy || return 1;;
		  *)extract_b43 || return 1
		    extract_legacy || return 1;;
	esac
}

ipw_func() {
	download_func "$IPW2100_URL" ipw2100-fw-1.3.tgz #<==>ipwireless
	download_func "$IPW2200_URL" ipw2200-fw-3.1.tgz
	(
	cd $TEMP
	mkdir -p ipw2100
	tar xf ipw2100-fw-1.3.tgz -C ipw2100
	mv ipw2100/LICENSE ipw2100/LICENSE.ipw2100-fw
	tar xf ipw2200-fw-3.1.tgz
	cp -af ipw2100/* "$FIRMWARE_INSTALL_DIR_XTRA"
	cp -af ipw2200-fw-3.1/* "$FIRMWARE_INSTALL_DIR_XTRA"
	)
}

clear_tmp() {
	rm -rf ${TEMP}/* # ditch it all
}

fw_msg() {
	echo -n "$1 "
	read f m <<<$1
	n=${#f}
	x=$((60 -$n))
	fmt="%s%${x}s\n"
	[ -n "$m" ] && printf "$fmt" "$f" "$m" >> $2 || \
	printf "%s\n" "$f" >> $2
}

b43_func
ipw_func

B43KO=`find "$module_dir" -type f -name "b43*.ko"`; IPWKO=`find "$module_dir" -type f -name "ipw2?00.ko"`
for xx in $B43KO $IPWKO
do
	modinfo "$xx" -F firmware | while read fw
	do 
		fw_dir=${fw%\/*} # dirname
		if [ "$fw" = "$fw_dir" ];then # not in subdir
			if [ -e "$SRC_FW_DIR/$fw" ];then
				cp -L -n $SRC_FW_DIR/$fw $FIRMWARE_RESULT_DIR
				fw_msg $fw $fw_tmp_list_xtra # log to zdrv
			else
				fw_msg "${fw} missing" $fw_tmp_list_xtra # log to zdrv
			fi
		else
			if [ -e "$SRC_FW_DIR/$fw" ];then
				mkdir -p $FIRMWARE_RESULT_DIR/$fw_dir
				cp -L -n $SRC_FW_DIR/$fw $FIRMWARE_RESULT_DIR/$fw_dir
				fw_msg $fw $fw_tmp_list_xtra # log to zdrv
			else
				fw_msg "${fw} missing" $fw_tmp_list_xtra # log to zdrv
			fi
		fi
	done
done
mkdir -p $FIRMWARE_RESULT_DIR/licences
cp -f $SRC_FW_DIR/LICEN?E* $FIRMWARE_RESULT_DIR/licences

clear_tmp
