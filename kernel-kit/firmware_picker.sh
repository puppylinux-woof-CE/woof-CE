#!/bin/sh

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
FIRMWARE_RESULT_DIR='zfirmware_workdir/lib/firmware'

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
		git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
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
	find ${SRC_FW_DIR} -type f -iname 'licen?e*' -exec cp '{}' ${FIRMWARE_RESULT_DIR}/licences \;
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

module_dir=output/${linux_kernel_dir}/lib/modules
mkdir -p $FIRMWARE_RESULT_DIR
firmware_list_dir=output/${linux_kernel_dir}/etc/modules/
mkdir -p $firmware_list_dir
fw_list=${firmware_list_dir}/firmware.lst.${kernel_version}
echo "### If 'non-free' is after a firmware entry it is non-free and will need to be found elsewhere" > $fw_list

# find the modules and see what firmware they need
# NOTE 0: modinfo to the actual full path to the .ko module file works
# NOTE 1: some firmware files won't exist because they are proprietary
# broadcom wireless is an example, and some dvb tuners and some bluetooth
for m in `find "$module_dir" -type f -name "*.ko"`
do
	modinfo "$m" -F firmware | while read fw
	do 
		fw_dir=${fw%\/*} # dirname
		if [ "$fw" = "$fw_dir" ];then # not in subdir
			if [ -e "$SRC_FW_DIR/$fw" ];then
				cp -d $SRC_FW_DIR/$fw $FIRMWARE_RESULT_DIR
				fw_msg $fw $fw_list # log to zdrv
			else
				fw_msg "${fw} non-free" $fw_list # log to zdrv
				continue
			fi
		else
			if [ -e "$SRC_FW_DIR/$fw" ];then
				mkdir -p $FIRMWARE_RESULT_DIR/$fw_dir
				cp -d $SRC_FW_DIR/$fw $FIRMWARE_RESULT_DIR/$fw_dir
				fw_msg $fw $fw_list # log to zdrv
			else
				fw_msg "${fw} non-free" $fw_list # log to zdrv
				continue
			fi
		fi		
	done
done

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
