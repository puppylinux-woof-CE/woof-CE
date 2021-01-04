#!/bin/sh
# install huge kernel to build
# * called by 3builddistro
# * can be run independently
# * we're in sandbox3

. ../_00build.conf
[ -f ../_00build_2.conf ] && . ../_00build_2.conf
. ../DISTRO_SPECS

if [ -L woof-code ] ; then # zwoof-next
	HUGE_KERNEL_DIR=workdir/huge_kernel
else
	HUGE_KERNEL_DIR=../huge_kernel
fi

if [ ! -d ../../local-repositories/huge_kernels ] ; then
	rm -f ../../local-repositories/huge_kernels
fi

mkdir -p ../../local-repositories/huge_kernels
mkdir -p build
[ -z $ZDRVSFS ] && ZDRVSFS="zdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z $FDRVSFS ] && FDRVSFS="fdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"

#-----------------------------------------

echo "Installing HUGE kernel to build/"
sleep 1

# see if there is one in kernel-kit
if [ -d '../kernel-kit/output' ];then
	KIT_KERNEL=`find ../kernel-kit/output -maxdepth 1 -type f -name 'huge*.tar*' |grep -v 'txt$' | head -n1`
	[ -z "$KIT_KERNEL" ] || cp $KIT_KERNEL ${HUGE_KERNEL_DIR}/
	# while we are here, we'll copy in fdrive if it exists
	FDRIVE=`find ../kernel-kit/sources -maxdepth 1 -type f -name 'fdrv*.sfs'`
	if [ "$FDRIVE" ];then
	  if [ -z "$KFDRIVE" ];then
		FSIZE=`stat -c %s $FDRIVE`
		FSIZE=$(($FSIZE / 1000000))
		echo "An 'F' drive if has been found. This contains supplementary firmware"
		echo "that can be included in the final build. It will add ${FSIZE}MB to the"
		echo "final image. It does no harm not to include, just some exotic drivers"
		echo "may not work."
		echo "Alternatively, you can shift the contents of ${FDRIVE##*/}"
		echo "to sandbox3/fdrv and later in this script you are offered to download"
		echo "and build some non-free firmwares that will be added to the ${FDRIVE##*/}"
		echo "Press 'F' then 'Enter' to include, 'M' then enter to mount the fdrive"
		echo "and copy the contents to sandbox3 it or just 'Enter' to skip."
		read include_fdrive
		case $include_fdrive in
		  f|F)
			echo "copying $FDRVSFS to build"
			cp $FDRIVE build/$FDRVSFS
			KFDRIVE=yes # will conflict with non-free fdrv below
			;;
		  m|M)
			echo "mounting $FDRIVE" # this is compatible with non-free fdrv
			FREEDEV=$(losetup -f)
			losetup ${FREEDEV} ${FDRIVE}
			mkdir -p /mnt/fdrv
			mount -r -t squashfs ${FREEDEV} /mnt/fdrv
			mkdir -p fdrv #we're in sandbox3
			echo "copying files..."
			cp -a -u --remove-destination /mnt/fdrv/* fdrv/
			sync
			umount /mnt/fdrv
			rm -rf /mnt/fdrv
			losetup -a | grep -o -q "${FREEDEV##*/}" && losetup -d $FREEDEV
			echo "done"
		    ;;
		  *)
			echo "Skipping f drive."
			KFDRIVE=no
			;;
		esac
	  else
		case $KFDRIVE in
		  yes)
			echo "copying $FDRVSFS to build"
			cp $FDRIVE build/$FDRVSFS
			;;
		  *)
			echo "not copying ${FDRIVE##*/}" # KFDRIVE is already 'no'
			;;
		esac
	  fi
	fi
fi

#----------

mkdir -p ${HUGE_KERNEL_DIR}
IS_KERNEL=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | wc -l`

#==========
# functions
#==========

download_kernel() {
	local URL="$1" TARBALL="${1##*/}"
	if [ ! -f ../../local-repositories/huge_kernels/${TARBALL} ] ; then
		if [ -f ${HUGE_KERNEL_DIR}/${TARBALL} ] ; then
			cp ${HUGE_KERNEL_DIR}/${TARBALL} ../../local-repositories/huge_kernels/${TARBALL}
		fi
	fi
	../support/download_file.sh "$URL" ../../local-repositories/huge_kernels || \
		../support/download_file.sh "$URL" ../../local-repositories/huge_kernels
	[ $? -ne 0 ] && exit 1
	if [ ! -f ${HUGE_KERNEL_DIR}/${TARBALL} ] ; then
		cp ../../local-repositories/huge_kernels/${TARBALL} ${HUGE_KERNEL_DIR}/${TARBALL}
	fi
}

choose_kernel_to_download() {
	TMP=/tmp/kernels$$
	TMP2=/tmp/kernels2$$
	wget ${KERNEL_REPO_URL} -O $TMP
	if [ $? -ne 0 ] ; then
		echo "Could not get kernel list"
		echo "If you have connectivity issues (or the site is unreachable)"
		echo " place a huge kernel in the 'huge_kernel' directory"
		echo "Type A in hit enter to retry, any other key to exit"
		read zzz
		case $zzz in
			A|a) exec $0 ;;
			*) exit 1 ;;
		esac
	fi
	# grok out what kernels are available
	c=1
	cat $TMP|tr '>' ' '|tr '<' ' '|tr ' ' '\n'|grep -v 'md5'| \
		grep -v 'kernels'|grep 'huge'|grep -v 'href'|\
		while read q
		do
			echo "$c $q" >> $TMP2
			c=$(($c + 1))
		done
	while [ 1 ]
	do
		echo "Please choose the number of the kernel you wish to download"
		cat $TMP2
		read choice_k
		choice=`grep "^$choice_k " $TMP2`
		[ ! "$choice" ] && echo "invalid choice" && continue
		echo "You chose ${choice##* }."
		sleep 3
		break
	done
	download_kernel "$KERNEL_REPO_URL/${choice##* }"
	rm $TMP
	rm $TMP2
}

choose_kernel() {
	TMP=/tmp/kernels3$$
	x=1
	for j in `ls -1 ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null |grep -v 'md5'`
	do
		echo "$x $j" >> $TMP
		x=$(($x + 1))
	done
	while [ 1 ]
	do
		echo "Please choose the number of the kernel you wish to use"
		cat $TMP
		read choice_k3
		choice3=`grep ^$choice_k3 $TMP`
		[ ! "$choice3" ] && echo "invalid choice3" && continue
		echo "You chose ${choice3##* }."
		sleep 3
		break
	done
	KERNEL_VERSION=`echo ${choice3##* } |cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
	rm $TMP
}
#==========
if [ "$KERNEL_TARBALL_URL" != "" ] ; then # if specified get it
	download_kernel ${KERNEL_TARBALL_URL} #build.conf
	KERNEL_VERSION=${KERNEL_TARBALL_URL##*/}
	KERNEL_VERSION=`echo ${KERNEL_VERSION#*\-}|sed 's/\.tar.*$//'`
else
	if [ "$IS_KERNEL" = 0 ] ; then
		#no kernel, get 1
		choose_kernel_to_download
	fi
	
	IS_KERNEL2=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | wc -l`
	
	if [ "$IS_KERNEL2" -gt 1 ] ; then
		#too many, choose 1
		choose_kernel
	elif [ "$IS_KERNEL2" == 1 ] ; then
		# 1 kernel
		# check if it was a failed/incomplete download
		# as it keeps hitting the same error everytime you
		# run 3builddistro
		if [ "$IS_KERNEL" == 1 ] ; then
			KERNEL_VERSION=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | grep -v 'md5'|cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
			download_kernel "$KERNEL_REPO_URL/$(basename ${HUGE_KERNEL_DIR}/huge-${KERNEL_VERSION}.tar.*)"
		fi
		KERNEL_VERSION=`ls ${HUGE_KERNEL_DIR}/*.tar.* 2>/dev/null | grep -v 'md5'|cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
	fi
fi

echo "Kernel is $KERNEL_VERSION version"
export KERNEL_VERSION

cp -a ${HUGE_KERNEL_DIR}/huge-${KERNEL_VERSION}.tar.* build/

cd build
tar -xvf huge-${KERNEL_VERSION}.tar.*
[ "$?" = 0 ] || exit 1
rm -f huge-${KERNEL_VERSION}.tar.* #remove pkg
mv -f kernel-modules*$KERNEL_VERSION* $ZDRVSFS
mv -f vmlinuz-$KERNEL_VERSION vmlinuz
mv -f fdrv* $FDRVSFS
cd ..

exit 0

### END ###
