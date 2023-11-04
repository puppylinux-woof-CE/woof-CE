#!/bin/bash

# GPL-V2 or later at your discretion
# (c) Mick Amadio, 2020 01micko@gmail.com, Gold Coast QLD, Australia

# this script depends on modinfo to get firmware version of modules
# in the target kernel. Installs correct version from linux-firmware
# to the fdrv (option 'f') or zdrv (builtin - option 'b')

export LANG=C #faster
. ./build.conf

# vars
CWD=`pwd`
BUILD_LOG=${CWD}/build.log
SRC_FW_DIR='../linux-firmware'
FIRMWARE_SFS="output/${FDRV}"
export FIRMWARE_RESULT_DIR='zfirmware_workdir/lib/firmware'

## functions
log_msg()    { echo -e "$@" ; echo -e "$@" >> ${BUILD_LOG} ; }

fw_msg() {
	echo -n "$1 "
	read f m <<<$1
	n=${#f}
	x=$((60 -$n))
	fmt="%s%${x}s\n"
	[ -n "$m" ] && printf "$fmt" "$f" "$m" >> $2 || \
	printf "%s\n" "$f" >> $2
}

exit_error() { log_msg "$@"  ; exit 1 ; }

func_git() {
	if [ -d "$SRC_FW_DIR" ];then
		cd $SRC_FW_DIR
		log_msg "Updating the git firmware repo"
		git pull
		[ $? -ne 0 ] && log_msg "Failed to update git firmware" # non fatal
		return 0 # precaution
	else
		cd ..
		log_msg "Cloning the firmware repo may take a long time"
		git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
		if [ $? -ne 0 ];then
			log_msg "Failed to clone the git firmware repo"
			return 1
		fi
		return 0
	fi
}

licence_func () {
	log_msg "Extracting licences"
	mkdir -p ${FIRMWARE_RESULT_DIR}/licences
	cp -f $SRC_FW_DIR/LICEN?E* $FIRMWARE_RESULT_DIR/licences
}
##

case $1 in
	f)log_msg "building firmware for fdrv" && sleep 1 ;; # separate fdrv
	b)log_msg "building firmware for zdrv" && sleep 1 ;; # builtin
	*)exit_error "unrecognised option"   ;;
esac

# update or clone git firmware
if [ "$GIT_ALREADY_DOWNLOADED" != "yes" ] ; then
	func_git || exit_error "Error"
fi

cd ${CWD}

[ -f "${FIRMWARE_SFS}" ] && rm -f ${FIRMWARE_SFS}

export module_dir=output/${linux_kernel_dir}/lib/modules
mkdir -p $FIRMWARE_RESULT_DIR
firmware_list_dir=output/${linux_kernel_dir}/etc/modules/
mkdir -p $firmware_list_dir
fw_list=${firmware_list_dir}/firmware.lst.${kernel_version}
fw_tmp_list=/tmp/firmware.lst.${kernel_version}
echo "### If 'missing' is after a firmware entry it is missing or non-free and will need to be found elsewhere" > $fw_list

# find the modules and see what firmware they need
# NOTE 0: modinfo to the actual full path to the .ko module file works
# NOTE 1: some firmware files won't exist because they are proprietary
# broadcom wireless is an example, and some dvb tuners and some bluetooth

intelbt=0
for m in `find "$module_dir" -type f -name "*.ko"`
do
	modinfo "$m" -F firmware | while read fw
	do 
		fw_dir=${fw%\/*} # dirname
		if [ "$fw" = "$fw_dir" ];then # not in subdir
			case $fw in
				iwlwifi*) # some iwlwifi versions differ from modinfo
				fw_ver=${fw%\.*}
				fw_ver=${fw_ver##*\-}
				case $fw_ver in
					''|*[!0-9]*)continue ;; # skip as version is not an integer
					*)
					c=$fw_ver
					limit=$(($c - 4))
					# look for an older verion
					while [ $c -ge $limit ] ; do
						if [ -e "$SRC_FW_DIR/${fw%\-*}-${c}.${fw#*\.}" ];then
							cp -L -n $SRC_FW_DIR/${fw%\-*}-${c}.${fw#*\.} $FIRMWARE_RESULT_DIR
							fw_msg ${fw%\-*}-${c}.${fw#*\.} $fw_tmp_list # log to zdrv
							break
						else
							fw_msg "${fw} missing" $fw_tmp_list # log to zdrv
							c=$(($c - 1))
						fi
					done
					;;
				esac
				;;
				*) # others
				if [ -e "$SRC_FW_DIR/$fw" ];then
					cp -L -n $SRC_FW_DIR/$fw $FIRMWARE_RESULT_DIR
					fw_msg $fw $fw_tmp_list # log to zdrv
				else
					fw_msg "${fw} missing" $fw_tmp_list # log to zdrv
				fi
				;;
			esac
		else
			case $fw in
				intel/ibt-*.sfi|intel/ibt-*.ddc) # intel/ibt-%u-%u.sfi is formatted at runtime
				[ $intelbt -eq 1 ] && continue
				mkdir -p $FIRMWARE_RESULT_DIR/intel
				for F in $SRC_FW_DIR/intel/ibt-*.{sfi,ddc} $SRC_FW_DIR/intel/ibt-hw-*.bseq;do
					cp -L -n $F $FIRMWARE_RESULT_DIR/intel
					fw_msg ${F#$SRC_FW_DIR/} $fw_tmp_list # log to zdrv
				done
				intelbt=1
				continue
				;;
			esac

			if [ -e "$SRC_FW_DIR/$fw" ];then
				mkdir -p $FIRMWARE_RESULT_DIR/$fw_dir
				cp -L -n $SRC_FW_DIR/$fw $FIRMWARE_RESULT_DIR/$fw_dir
				fw_msg $fw $fw_tmp_list # log to zdrv
			else
				fw_msg "${fw} missing" $fw_tmp_list # log to zdrv
			fi
		fi		
	done

	case $m in
	*/ath*k*.ko) # some firmware doesn't appear in modinfo
	fw_top_dir=${m##*/}
	fw_top_dir=${fw_top_dir%%_*}
	fw_top_dir=${fw_top_dir%.ko}
	strings -a $m > /tmp/modstrings
	for F in $SRC_FW_DIR/$fw_top_dir/*/hw*;do
		fw_subdir=${F#$SRC_FW_DIR/}
		[ -e $FIRMWARE_RESULT_DIR/$fw_subdir ] && continue
		grep -Fqlm1 ${fw_subdir#$fw_top_dir/} /tmp/modstrings || continue
		mkdir -p $FIRMWARE_RESULT_DIR/${fw_subdir%/*}
		cp -r -L -n $F $FIRMWARE_RESULT_DIR/${fw_subdir%/*}
		fw_msg $fw_subdir $fw_tmp_list # log to zdrv
	done
	rm -f /tmp/modstrings
	;;
	*/ralink/rt*/rt*.ko) # rt2800pci doesn't list rt3290.bin
	strings -a $m > /tmp/modstrings
	for F in $SRC_FW_DIR/rt*.bin;do
		grep -Fqlm1 ${F##*/} /tmp/modstrings || continue
		cp -L -n $F $FIRMWARE_RESULT_DIR
		fw_msg ${F##*/} $fw_tmp_list # log to zdrv
	done
	rm -f /tmp/modstrings
	;;
	*/amdgpu.ko|*/radeon.ko) # some paths are formatted at runtime and don't appear in modinfo, i.e. radeon/%s_mec2.bin
	for F in $SRC_FW_DIR/`basename "$m" .ko`/*_*.bin;do
		fw_subdir=${F#$SRC_FW_DIR/}
		fw_subdir=${fw_subdir%/*}
		fw_basename=${F##*/}
		[ -e ${FIRMWARE_RESULT_DIR}/${fw_subdir}/${fw_basename} ] && continue
		[ -z "`ls ${FIRMWARE_RESULT_DIR}/${fw_subdir}/${fw_basename%%_*}_*.bin 2>/dev/null`" ] && continue
		cp -L -n $F ${FIRMWARE_RESULT_DIR}/${fw_subdir}
		fw_msg ${fw_subdir}/${fw_basename} $fw_tmp_list # log to zdrv
	done
	;;
	*/btusb.ko)
	mkdir -p ${FIRMWARE_RESULT_DIR}/qca
	for F in $SRC_FW_DIR/qca/rampatch_usb_[0-9]*.bin $SRC_FW_DIR/qca/nvm_usb_[0-9]*.bin;do
		[ -e ${FIRMWARE_RESULT_DIR}/qca/${F##*/} ] && continue
		cp -L -n $F ${FIRMWARE_RESULT_DIR}/qca/
		fw_msg ${F#$SRC_FW_DIR/} $fw_tmp_list # log to zdrv
	done
	;;
	*/btqca.ko)
	mkdir -p ${FIRMWARE_RESULT_DIR}/qca
	for F in $SRC_FW_DIR/qca/rampatch_[0-9]*.bin $SRC_FW_DIR/qca/nvm_[0-9]*.bin $SRC_FW_DIR/qca/*v[0-9]*.bin;do
		[ -e ${FIRMWARE_RESULT_DIR}/qca/${F##*/} ] && continue
		cp -L -n $F ${FIRMWARE_RESULT_DIR}/qca/
		fw_msg ${F#$SRC_FW_DIR/} $fw_tmp_list # log to zdrv
	done
	;;
	esac
done
# extra firmware from other sources
if [ -n "`find $module_dir -name 'snd-sof*.ko' | head -n 1`" ];then
	if command -v jq > /dev/null;then
		./get_sof.sh `pwd`/zfirmware_workdir || exit 1
	else
		log_msg "jq is missing, skipping get_sof.sh"
		[ -n "$GITHUB_ACTIONS" ] && exit 1
	fi
fi
if [ "$EXTRA_FW" = 'yes' ];then
	./firmware_extra.sh
	sed -i -e '/^b43/d' -e '/^ipw/d' $fw_tmp_list
	cat /tmp/firmware_extra.lst >> $fw_tmp_list
	rm -f /tmp/firmware_extra.lst
fi
sort -u < $fw_tmp_list >> $fw_list
rm $fw_tmp_list

# extract licences
licence_func

# copy firmwares to build
case $1 in
	f)[ -f "$FIRMWARE_SFS" ] && rm $FIRMWARE_SFS
		[ -d "output/${linux_kernel_dir}/lib/firmware/" ] && rm -rf output/${linux_kernel_dir}/lib/firmware/ # redundant; also not in newer kernels
		mksquashfs zfirmware_workdir $FIRMWARE_SFS $COMP
		(cd output/;md5sum ${FIRMWARE_SFS##*/} > ${FIRMWARE_SFS##*/}.md5.txt);;
	b)[ -d "output/${linux_kernel_dir}/lib/firmware/" ] && rm -r output/${linux_kernel_dir}/lib/firmware/* ||\
			mkdir -p output/${linux_kernel_dir}/lib/firmware/
		cp -r -n $FIRMWARE_RESULT_DIR/* output/${linux_kernel_dir}/lib/firmware/ ;;
esac

rm -rf zfirmware_workdir
log_msg "Firmware script complete."
