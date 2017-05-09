#!/bin/bash
# called from build.sh (kernel-kit)
# download & process linux-firmware git

. ./build.conf || exit 1

export LANG=C #faster
DEBUG=0 #0=disabled, 1=enabled

rm -f ./fw-*.log
[ $DEBUG -ne 1 -a -d zfirmware_workdir ] && rm -r zfirmware_workdir
CWD=`pwd`

# busybox stat faster?
busybox|grep -qow 'stat' && STAT='busybox stat' || STAT=stat


# vars
SRC_FW_DIR='../linux-firmware'
DEST_FW_DIR='zfirmware_workdir/lib'

SRC_FILE_FW=${SRC_FW_DIR}/WHENCE
dotconfig=`find output -maxdepth 1 -type f -name 'DOTconfig*' | head -1`
if [ -f "$dotconfig" ] ; then
	DOTCONFIG_str=$(grep -v -E '^#|is not set$' $dotconfig)
else
	echo "WARNING: No DOTconfig file in output/"
	echo "Put a DOTconfig file there..."
	#exit 1
fi

FIRMWARE_SFS="sources/fdrv_${kernel_version}_${package_name_suffix}.sfs"
FIRMWARE_RESULT_DIR='zfirmware_workdir/lib/firmware'
FIRMWARE_EXTRA_DIR='zfirmware_workdir/lib/linux-firmware'

kernel_package=`find output -type d -name 'linux_kernel*' | head -1`

if [ ! -d "${kernel_package}" ] ; then
	kernel_package=`find $CWD -type d -name 'linux_kernel*' | head -1`
fi

#if [ ! -d "${kernel_package}" ] ; then
#	echo "WARNING: No kernel package..."
#	#exit 1
#else
	dest_kernel_package=${kernel_package}/lib/firmware
	[ ! -d ${dest_kernel_package} ] && mkdir -p $dest_kernel_package
#fi


#################################################################
#                          FUNCTIONS
#################################################################

func_git() {
	if [ -d "$SRC_FW_DIR" ];then
		cd $SRC_FW_DIR
		echo "Updating the git firmware repo"
		git pull
		[ $? -ne 0 ] && echo "Failed to update git firmware" # non fatal
		return 0 # precaution
	else
		cd ..
		echo "Cloning the firmware repo may take a long time"
		git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
		if [ $? -ne 0 ];then
			echo "Failed to clone the git firmware repo"
			return 1
		fi
		return 0
	fi
}

process_driver() {
	local driver=$1
	local DRIVER=${driver^^}
	DRIVER=${DRIVER//-/_}
	case $DRIVER in # try to avoid dups
		RADEON)   DRIVER='DRM_RADEON='    ;;
		NOUVEAU)  DRIVER='DRM_NOUVEAU='   ;;
		AMDGPU)   DRIVER='DRM_AMDGPU='    ;;
		I915)     DRIVER='DRM_I915='      ;;
		KEYSPAN)  DRIVER='SERIAL_KEYSPAN=';;
		LIBERTAS) DRIVER=LIBERTAS_USB     ;;
		MWIFIEX)  DRIVER=MWIFIEX_USB      ;;
		MWLWIFI)  DRIVER='CONFIG_MAC80211';; #see WHENCE, .config
	esac
	echo -n "$driver "
	D=`echo "$DOTCONFIG_str" | grep $DRIVER | head -n1`
	if [ -z "$D" ] ; then
		echo
		return 1
	else
		echo -- $D --
		return 0
	fi
}

get_func() {
	local file=${1}
	local source_path=${SRC_FW_DIR}/${file}
	local target_dir=${CWD}/${FIRMWARE_EXTRA_DIR}/${file}
	target_dir=${target_dir%/*} # strip off file
	if [ ! -d "${target_dir}" ] ; then # manufacture dest subdirs before move
		mkdir -p ${target_dir}
	fi
	cp -d ${source_path} ${target_dir} 2>/dev/null
	if [ $? -eq 0 ];then
		echo "$file 	`$STAT -c %s $SRC_FW_DIR/$file`" >> fw-1.log
	else
		echo "FAILURE: $file" >> fw-1.log
	fi
}

extract_firmware() {
	(
	while read -r field value etc ; do
		case $field in "Driver:")
			driver=$value
			# select firmware according based on DOTconfig...
			process_driver $driver || continue
			echo -n "$driver " >&2
			while [ 1 ] ; do
				read -r field value etc
				case $field in
					"File:") file=$value ; get_func $file ;;
					"License:"|"Licence:") break ;;
				esac
			done
		esac
	done < ${SRC_FILE_FW}
	) > fw-2.log
}

fw_filter(){
	list=$1
	[ -z "$2" ] && B=10000000 || B=$2 #~10MB (salesmen MB ;-)
	[ $B -eq 0 ] && B=10000000
	echo "Filtering with $list"
	(
	echo ; echo ; echo "Filtering with $list"
	echo 'FILTERED FIRMWARE LIST IN ZDRV'
	echo '=============================='
	mkdir -p ${FIRMWARE_RESULT_DIR}
	filelist=$(find ${FIRMWARE_EXTRA_DIR} | sed "s%${FIRMWARE_EXTRA_DIR}\/%%") # strip leading crap
	filelist2=$(find ${SRC_FW_DIR} | sed -e "s%${SRC_FW_DIR}\/%%" -e 's|\.git/||') # strip leading crap
	#echo "$filelist"
	while read line; do
		file=${line##*/}
		file2=${line}
		action=mv #move
		echo -n "$file " >&2
		file_path=`echo "$filelist" | grep "^${file2}$" | head -n1`
		if [ ! "$file_path" ] ; then
			file_path=`echo "$filelist" | grep "\/${file}$" | head -n1`
			[ -z "$file_path" ] && continue
		fi
		source_path=${FIRMWARE_EXTRA_DIR}/${file_path}
		[ -f ${source_path} -o -h ${source_path} ] || continue
		target_dir=${FIRMWARE_RESULT_DIR}/${file_path}
		target_dir=${target_dir%/*} # strip off file
		if [ ! -d "${target_dir}" ] ; then # manufacture dest subdirs before move
			mkdir -p ${target_dir}
		fi
		# make sure links follow targets
		[ -h "${source_path}" -a -e "${source_path}" ] && SSIZE=`$STAT -L -c %s ${source_path}` || SSIZE=`stat -c %s ${source_path}`
		[ -z "$SSIZE" ] && continue #precaution
		[ $SSIZE -gt "$B" ] && continue ##discard bigguns
		# do links first?
		ret=0
		[ -h "${source_path}" ] && ${action} -f ${source_path} ${target_dir}/ #2>>fw-2.log
		ret=$?
		[ -e "${source_path}" ] && ${action} -f ${source_path} ${target_dir}/
		ret=$(($ret + $?))
		[ $ret -le 1 ] && echo "${file} SUCCESS" || echo "${file} FAIL"
	done < $list
	) >> fw-2.log
}

licence_func () {
	echo "Extracting licences"
	mkdir -p ${FIRMWARE_RESULT_DIR}/licences
	find ${SRC_FW_DIR} -type f -iname 'licen?e*' -exec cp '{}' ${FIRMWARE_RESULT_DIR}/licences \;
}

#################################################################
#                             MAIN
#################################################################

# update or clone git firmware
if [ "$GIT_ALREADY_DOWNLOADED" != "yes" ] ; then
	func_git || { echo "ERROR" ; exit 1 ; }
fi

cd ${CWD}

[ -d "$DEST_FW_DIR" ] && rm -rf "$DEST_FW_DIR"
mkdir -p "$DEST_FW_DIR"
[ -f "${FIRMWARE_SFS}" ] && rm -f ${FIRMWARE_SFS}

# cut down firmware .. or not
FW_FLAG=$1;
if [ ! "$FW_FLAG" -a -z "$CUTBYTES" ] ; then
	echo -n "
Cut down firmware?
1. Cut down according to firmware.lst [default]
2. Cut down according to built modules (needs work)
3. Don't cut down

Choose option: " ; read cdf
	case $cdf in
		2) FW_FLAG="big" ;;
		3) FW_FLAG="complete" ;;
		*) FW_FLAG="" ;;
	esac
fi

case $FW_FLAG in
	complete)
		mkdir -p ${FIRMWARE_RESULT_DIR}
		echo "Copy all firmware"
		cp -an ${SRC_FW_DIR}/* ${FIRMWARE_RESULT_DIR}/
		rm -rf ${FIRMWARE_RESULT_DIR}/.git ${FIRMWARE_RESULT_DIR}/LICEN*
		licence_func
		if [ -d "${dest_kernel_package}" ] ; then
			cp -an ${FIRMWARE_RESULT_DIR}/* ${dest_kernel_package}/
			rm -r ${FIRMWARE_RESULT_DIR}
		else
			mksquashfs zfirmware_workdir ${FIRMWARE_SFS##*/} -comp xz
			md5sum ${FIRMWARE_SFS##*/} > ${FIRMWARE_SFS##*/}.md5.txt
		fi
		;;
	big)
		echo "Extracting firmware"
		extract_firmware # process entries in WHENCE
		echo
		#main_proc
		echo="Not filtering"
		mv ${FIRMWARE_EXTRA_DIR} ${FIRMWARE_RESULT_DIR}
		licence_func
		if [ -d "${dest_kernel_package}" ] ; then
			cp -n -r ${FIRMWARE_RESULT_DIR}/* ${dest_kernel_package}/
		fi
		;;
	*)
		# create new list.. now gets filtered by size and obscure (= big ones deleted)
		# obscure fw are liquidio, phanfw.bin (netxen_nic) and cxgb{3,4} (chelsio) - mainly in servers
		grep '^File' $SRC_FILE_FW |grep -oE '\: [a-zA-Z].*|\: L.*|\: [0-9].*'|sed 's/^\: //'|grep -vE 'liquidio|cxgb[34]|phanfw.bin' > firmware.lst
		# choose
		if [ ! "$CUTBYTES" ];then
			echo -n "
Cut down firmware more?
1. Cut down with some big, mostly obscure firmware removed (default)
2. Cut down eliminating fw bigger than 1.5MB - usually safe
3. Cut down eliminating fw bigger than 1MB - may cut wifi support
4. Cut down eliminating fw bigger than 500KB - use at own risk
5. Cut down eliminating fw bigger than 250KB - are you insane?

Choose option: " ; read cdfplus
			case $cdfplus in
				2) CUTBYTES=1500000 ;;
				3) CUTBYTES=1000000 ;;
				4) CUTBYTES=500000 ;;
				5) CUTBYTES=250000 ;;
				*) CUTBYTES=0 ;;
			esac
		fi
		echo "Extracting firmware"
		extract_firmware # process entries in WHENCE
		echo
		fw_filter firmware.lst $CUTBYTES
		find ${FIRMWARE_EXTRA_DIR} -type d -empty -delete
		licence_func
		# copy final fw to kernel
		if [ -d "${dest_kernel_package}" ] ; then
			cp -n -r ${FIRMWARE_RESULT_DIR}/* ${dest_kernel_package}/
		fi
		rm -r ${FIRMWARE_RESULT_DIR}
		# now move the extras to / lib/firmware & make sfs
		mv ${FIRMWARE_EXTRA_DIR} ${FIRMWARE_RESULT_DIR}
		mksquashfs zfirmware_workdir ${FIRMWARE_SFS} -comp xz
		md5sum ${FIRMWARE_SFS} > ${FIRMWARE_SFS}.md5.txt
		;;
esac

(
	echo '================'
	echo "FIRMWARE IN FDRV"
	echo '================'
	cat fw-1.log
	echo '=============================='
	[ -f ${list}.log ] && cat ${list}.log && rm ${list}.log
) &>> build.log

# cleanup
if [ $DEBUG -ne 1 ] ; then
	rm -f fw-*.log
	rm -rf zfirmware_workdir
fi
echo "Firmware script complete."

### END ###
