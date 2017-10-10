#!/bin/sh
# install huge kernel to build
# * called by 3builddistro
# * can be run independently
# * we're in sandbox3

. ../_00build.conf
. ../DISTRO_SPECS

if [ ! -d ../../local-repositories/huge_kernels ] ; then
	rm -f ../../local-repositories/huge_kernels
fi

mkdir -p ../../local-repositories/huge_kernels

# precaution
mkdir -p build
[ -z $PUPPYSFS ] && PUPPYSFS="puppy_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z $ZDRVSFS ] && ZDRVSFS="zdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z $FDRVSFS ] && FDRVSFS="fdrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z $ADRVSFS ] && ADRVSFS="adrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z $YDRVSFS ] && YDRVSFS="ydrv_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
[ -z $DEVXSFS ] && DEVXSFS="devx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"

#-----------------------------------------

echo "Installing HUGE kernel to build/"
sleep 1

# see if there is one in kernel-kit
if [ -d '../kernel-kit/output' ];then
	KIT_KERNEL=`find ../kernel-kit/output -maxdepth 1 -type f -name 'huge*.tar*' |grep -v 'txt$' | head -n1`
	[ -z "$KIT_KERNEL" ] || cp $KIT_KERNEL ../huge_kernel/
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

mkdir -p ../huge_kernel
IS_KERNEL=`ls ../huge_kernel/*.tar.* 2>/dev/null | wc -l`

#==========
# functions
#==========

download_kernel() {
	local URL="$1" TARBALL="${1##*/}"
	if [ -f ../../local-repositories/huge_kernels/${TARBALL} ] ; then
		echo "Verifying ../../local-repositories/huge_kernels/${TARBALL}"
		if tar -taf ../../local-repositories/huge_kernels/${TARBALL} &>/dev/null ; then
			cp -fv ../../local-repositories/huge_kernels/${TARBALL} ../huge_kernel/
			return
		fi
	elif [ -f ../huge_kernel/${TARBALL} ] ; then
		echo "Verifying ../huge_kernel/${TARBALL}"
		if tar -taf ../huge_kernel/${TARBALL} &>/dev/null ; then
			cp -fv ../huge_kernel/${TARBALL} ../../local-repositories/huge_kernels/
			return
		fi
	fi
	#---------------------------------
	wget -t0 -c $URL -P ../huge_kernel
	wget ${URL}.md5.txt -P ../huge_kernel
	CHK=`md5sum ../huge_kernel/${TARBALL} | cut -d ' ' -f1`
	# - md5.txt file might not be available: 404  not found
	# -  e.g.: huge-3.14.79-tahr_noPAE.tar.bz2.md5
	MD5=`cat ../huge_kernel/${TARBALL}.md5.txt| cut -d ' ' -f1`
	# PROBLEM:
	# most md5.txt files only have MD5 sums
	#    da3c0c75d756926adaea56205c00715f  huge-3.4.94-slacko4G2-i686.tar.bz2
	# but a few others have this format
	#    # MD5
	#    b9264da180c2a8a08924058c1f17e56d  huge-4.9.15-xenialpup64.tar.bz2
	#    # SHA1
	#    7150b153a5d184ba3e3a6d9400b5817c099af8f2  huge-4.9.15-xenialpup64.tar.bz2
	#    # SHA256
	#    059db29d5aa006ced51bda1013e42a4ccf97af31839a00ecf660f19d021d2630  huge-4.9.15-xenialpup64.tar.bz2
	if [ ! -z "$MD5" ] ; then
		if grep -q '# MD5' ../huge_kernel/${TARBALL}.md5.txt ; then
			MD5=$(sed -n '2p' ../huge_kernel/${TARBALL}.md5.txt | cut -d ' ' -f1)
		fi
	fi
	echo "${TARBALL}         : $CHK"
	echo "${TARBALL}.md5.txt : $MD5"
	rm -f ../huge_kernel/${TARBALL}.md5.txt
	if [ -z "$MD5" ] ; then
		echo "*** WARNING: no checksum"
		echo "Verifying tarball integrity..."
		if ! tar -taf ../huge_kernel/${TARBALL} &>/dev/null ; then
			echo "ERROR"
			exit 1
		fi
	else
		if [ "$CHK" != "$MD5" ] ; then
			echo "checksum failed"
			exit 1
		fi
		echo "Checksum passed"
	fi
	cp -f ../huge_kernel/${TARBALL} ../../local-repositories/huge_kernels/
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
	for j in `ls -1 ../huge_kernel/*.tar.* 2>/dev/null |grep -v 'md5'`
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

if [ "$IS_KERNEL" = 0 ] ; then
	#no kernel, get 1
	if [ "$KERNEL_TARBALL_URL" != "" ] ; then
		download_kernel ${KERNEL_TARBALL_URL} #build.conf
	else
		choose_kernel_to_download
	fi
fi

IS_KERNEL2=`ls ../huge_kernel/*.tar.* 2>/dev/null | wc -l`

if [ "$IS_KERNEL2" -gt 1 ] ; then
	#too many, choose 1
	choose_kernel
elif [ "$IS_KERNEL2" == 1 ] ; then
	# 1 kernel
	# check if it was a failed/incomplete download
	# as it keeps hitting the same error everytime you
	# run 3builddistro
	if [ "$IS_KERNEL" == 1 ] ; then
		if [ "$KERNEL_TARBALL_URL" != "" ] ; then
			download_kernel ${KERNEL_TARBALL_URL} #build.conf
		else
			KERNEL_VERSION=`ls ../huge_kernel/*.tar.* 2>/dev/null | grep -v 'md5'|cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
			download_kernel "$KERNEL_REPO_URL/$(basename ../huge_kernel/huge-${KERNEL_VERSION}.tar.*)"
		fi
	fi
	KERNEL_VERSION=`ls ../huge_kernel/*.tar.* 2>/dev/null | grep -v 'md5'|cut -d '-' -f2-|rev|cut -d '.' -f3-|rev`
fi

echo "Kernel is $KERNEL_VERSION version"
export KERNEL_VERSION

cp -a ../huge_kernel/huge-${KERNEL_VERSION}.tar.* build/

cd build
tar -xvf huge-${KERNEL_VERSION}.tar.*
[ "$?" = 0 ] || exit 1
rm -f huge-${KERNEL_VERSION}.tar.* #remove pkg
mv -f kernel-modules.sfs-$KERNEL_VERSION $ZDRVSFS
mv -f vmlinuz-$KERNEL_VERSION vmlinuz
cd ..

exit 0

### END ###