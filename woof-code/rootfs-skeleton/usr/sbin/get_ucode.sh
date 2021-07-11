#!/bin/sh

# gets the correct AMD or Intel microcode for your processor for late loading
# GPLv2

set -e
exit_val() {
	rm -f $1
	exit $2
}

# only on supported CPU
case $(uname -m) in
	x86_64|i?86|amd64);;
	*)echo "$(uname -m) unsupported"; exit_val nul 2 
esac

# get the ucode version
VENDOR=$(grep -m1 '^vendor_id' /proc/cpuinfo)
VENDOR=${VENDOR#* }
case $VENDOR in
	GenuineIntel)
	iCPUFAM=
	MODEL=
	STEP=
	# refer https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files
	grep -E 'cpu family|model|stepping' /proc/cpuinfo | grep -v 'model name' | sort -u > /tmp/intel_ucode
	while read var 
	do 
		if [ "${var:0:10}" = 'cpu family' ];then
			iCPUFAM=${var##* }
		fi
	 	if [ "${var:0:5}" = 'model' ];then
			MODEL=${var##* }
		fi
		if [ "${var:0:8}" = 'stepping' ];then
			STEP=${var##* }
		fi	
	done </tmp/intel_ucode
	
	# convert to hex
	c=1
	for i in $iCPUFAM  $MODEL $STEP ; do 
		if [ ${#i} -lt 2 ] ;then # character count
			case $c in
				1)CHAR1=0;;
				2)CHAR2=0;;
				3)CHAR3=0;;
			esac
		else
			case $c in
				1)CHAR1= ;;
				2)CHAR2= ;;
				3)CHAR3= ;;
			esac
		fi
		[ $c -gt 3 ] && break # failed
		c=$(($c + 1))
	done
	INT_UCODE=$(printf "${CHAR1}%x-${CHAR2}%x-${CHAR3}%x\n" $iCPUFAM $MODEL $STEP)
	
	iURL=https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/raw/main/intel-ucode
	
	# download to /lib/firmware - must be root
	mkdir -p /lib/firmware/intel-ucode 
	if wget -q $iURL/$INT_UCODE -P /lib/firmware/intel-ucode ;then
		echo "$INT_UCODE installed succesfully"
		exit_val /tmp/intel_ucode 0
	else
		echo "$INT_UCODE failed to download"
		exit_val /tmp/intel_ucode 1
	fi
	;;
	AuthenticAMD)
	# refer https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/amd-ucode
	# get the file list
	curl -s https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/amd-ucode | grep -o 'plain.*bin' | sed 's/plain.*ucode\///' | sort | uniq > /tmp/amd_ucode
	aURL=https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/amd-ucode/
	aCPUFAM=$(grep 'cpu family' /proc/cpuinfo | sort -u)
	aCPUFAM=${aCPUFAM##* }
	if [ $aCPUFAM -lt 20 ];then # bobcat, llano, fusion, turion, k10
		grep -q 'microcode_amd.bin' /tmp/amd_ucode && AMD_UCODE='microcode_amd.bin' && exit_val /tmp/amd_ucode 0 || exit_val /tmp/amd_ucode 1
	else
		XaCPUFAM=$(printf "%x\n" $aCPUFAM)
		# convert to hex
		AMD_UCODE=$(grep "$XaCPUFAM" /tmp/amd_ucode)
		[ -z "$AMD_UCODE" ] && exit_val /tmp/amd_ucode 1
	fi
	mkdir -p /lib/firmware/amd-ucode 
	if wget -q $aURL/$AMD_UCODE -P /lib/firmware/amd-ucode ;then
		echo "$AMD_UCODE installed succesfully"
		exit_val /tmp/amd_ucode 0
	else
		echo "$AMD_UCODE failed to download"
		exit_val /tmp/amd_ucode 1
	fi
	;;
esac

