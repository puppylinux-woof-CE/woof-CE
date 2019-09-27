#!/bin/bash
# install kit kernel to build
# * called by 3builddistro
# * can be run independently
# * we're in sandbox3

KIT_KERNEL_REPO_URL=${KIT_KERNEL_REPO_URL:-http://distro.ibiblio.org/puppylinux/huge_kernels}

. ../_00build.conf
. ../DISTRO_SPECS

if [ "$DISTRO_TARGETARCH" = "" ]; then
	echo "ERROR: DISTRO_TARGETARCH not set."
	exit 1
fi

#==========
# functions
#==========

name_of() {
	local FILE_NAME="${1##*/}"
	# un-escape '+'
	FILE_NAME="${FILE_NAME//%2B/+}"
	echo "$FILE_NAME"
}


download_kernel() {
	local URL="$1"
	../support/download_file.sh "$URL" "../../local-repositories/${DISTRO_TARGETARCH}/kernels"
	if [ $? -ne 0 ] ; then
		../support/download_file.sh "URL" "../../local-repositories/${DISTRO_TARGETARCH}/kernels"
		[ $? -ne 0 ] && exit 1
	fi
}

choose_kernel_to_download() {

	# each element is a single string with the
	# filename, a space, followed by the URL.
	unset KIT_KERNEL_FILES_ARRAY
	declare -a KIT_KERNEL_FILES_ARRAY

	if [ "$TMP" = "" ]; then
		TMP=/tmp/kernels$$
		wget ${KIT_KERNEL_REPO_URL} -O $TMP
		if [ $? -ne 0 ] ; then
			echo "Could not get kernel list"
			echo "Maybe you have connectivity issues (or the site is unreachable)?"
			return 1
		fi
	fi


#------------------------------------------------------------------------------

	if [ "$KIT_KERNEL_REPO_URL" = "http://distro.ibiblio.org/puppylinux/huge_kernels" ]; then
		local TEMP_KIT_KERNEL_FILES="`grep -o '>kit.*\.xz' $TMP | sed 's%^>%%g' | sort -u`"
		local I=1
		for ONE_FILE in $TEMP_KIT_KERNEL_FILES
		do
			if [ ! -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${ONE_FILE}" ]; then
				KIT_KERNEL_FILES_ARRAY[$I]="$ONE_FILE $KIT_KERNEL_REPO_URL/$ONE_FILE"
				let "I += 1"
			fi
		done

	elif [ "$KIT_KERNEL_REPO_URL" != "${KIT_KERNEL_REPO_URL/github.com/}" ]; then
		local REPO_NAME="${KIT_KERNEL_REPO_URL##*github.com/}"
		local USERNAME="${KIT_KERNEL_REPO_URL##*github.com/}"
		USERNAME="${USERNAME%%/*}"
		REPO_NAME="${REPO_NAME##"$USERNAME"/}"
		REPO_NAME="${REPO_NAME%%/*}"

		local TEMP_KIT_KERNEL_FILES="`grep -o \"<a href=\\\"/${USERNAME}/${REPO_NAME}/blob/master/kit-kernel[^\\\"]*.xz\\\"\" $TMP | sed -e \"s%<a href=\\\"/${USERNAME}/${REPO_NAME}/blob/master/%%\" | sed -e 's/\"//'`"
		local I=1
		for ONE_FILE in $TEMP_KIT_KERNEL_FILES
		do
			if [ ! -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/`name_of "$ONE_FILE"`" ]; then
				KIT_KERNEL_FILES_ARRAY[$I]="`name_of $ONE_FILE` https://github.com/${USERNAME}/${REPO_NAME}/raw/master/$ONE_FILE"
				let "I += 1"
			fi
		done

	elif [ "$KIT_KERNEL_REPO_URL" != "${KIT_KERNEL_REPO_URL/gitlab.com/}" ]; then
		local REPO_NAME="${KIT_KERNEL_REPO_URL##*gitlab.com/}"
		local USERNAME="${KIT_KERNEL_REPO_URL##*gitlab.com/}"
		USERNAME="${USERNAME%%/*}"
		REPO_NAME="${REPO_NAME##"$USERNAME"/}"
		REPO_NAME="${REPO_NAME%%/*}"

		local TEMP_KIT_KERNEL_FILES="`grep -o \"href=\\\"/${USERNAME}/${REPO_NAME}/blob/master/kit-kernel[^\\\"]*.xz\\\"\" $TMP | sed -e \"s%href=\\\"/${USERNAME}/${REPO_NAME}/blob/master/%%\" | sed -e 's/\"//'`"
		local I=1
		for ONE_FILE in $TEMP_KIT_KERNEL_FILES
		do
			if [ ! -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/`name_of "$ONE_FILE"`" ]; then
				KIT_KERNEL_FILES_ARRAY[$I]="`name_of $ONE_FILE` https://gitlab.com/${USERNAME}/${REPO_NAME}/raw/master/$ONE_FILE"
				let "I += 1"
			fi
		done

#	elif # other site
		# TODO
	else
		echo "Unfortunately, support for ${KIT_KERNEL_REPO_URL}"
		echo "has not been added (yet) to support/kit_kernel.sh  Maybe you can help?"
	fi

#------------------------------------------------------------------------------

	if [ "${KIT_KERNEL_FILES_ARRAY[*]}" = "" ]; then
		echo "No new kernels found."
		return 0
	fi

	while [ 1 ]
	do
		echo
		echo "Please choose the number of the kernel you wish to download"
		I=1
		while [ "$I" -le "${#KIT_KERNEL_FILES_ARRAY[*]}" ]
		do
			echo "$I ${KIT_KERNEL_FILES_ARRAY[$I]%% *}"
			let "I += 1"
		done
		read kernel_nr
		# doing the comparison as ASCII so it will not give errors for non-numeric characters
		[ "$kernel_nr" \< "1" -o "$kernel_nr" \> "${#KIT_KERNEL_FILES_ARRAY[*]}" ] && echo "invalid choice" && continue
		echo "You chose ${KIT_KERNEL_FILES_ARRAY[$kernel_nr]%% *}"
		break
	done

#	echo "${KIT_KERNEL_FILES_ARRAY[$kernel_nr]##* }"
	download_kernel "${KIT_KERNEL_FILES_ARRAY[$kernel_nr]##* }"

	local THIS_KERNEL="${KIT_KERNEL_FILES_ARRAY[$kernel_nr]%% *}"
	if [ "$THIS_KERNEL" != "${THIS_KERNEL/-v7l/}" ]; then
		CHOSEN_KERNEL7L="$THIS_KERNEL"
	elif [ "$THIS_KERNEL" != "${THIS_KERNEL/-v7+/}" ]; then
		CHOSEN_KERNEL7="$THIS_KERNEL"
	else
		CHOSEN_KERNEL="$THIS_KERNEL"
	fi
}

choose_kernel() {
	if [ "${DISTRO_TARGETARCH}" = "arm" ]; then
		# pi 2,3
		local MENU7="$(cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
		I=1
		for ONE_KERNEL in kit-kernel-*-v7+*.tar.xz
		do
			echo "$I $ONE_KERNEL"
			let "I += 1"
		done
		)"
		# pi 4
		local MENU7l="$(cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
		I=1
		for ONE_KERNEL in kit-kernel-*-v7l*.tar.xz
		do
			echo "$I $ONE_KERNEL"
			let "I += 1"
		done
		)"
		# pi 0,1
		local MENU_NOT_7="$(cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
		I=1
		for ONE_KERNEL in kit-kernel-*\.*[!v][0-9]+*.tar.xz
		do
			echo "$I $ONE_KERNEL"
			let "I += 1"
		done
		)"
		CHOSEN_KERNEL=''
		CHOSEN_KERNEL7=''
		CHOSEN_KERNEL7L=''
		
		local kver
		local e=1
		echo "You can choose up to 3 Pi kernels for Pi 0 and 1; Pi 2 and 3; Pi 4 
series. The kernel for the appropriate board will be loaded.
All kernels must be the same version, so choices may be limited."
		echo
		while [ 1 ]
		do
			case "$e" in
				1)PI="zero, 1"
				menu="$MENU_NOT_7";;
				2)PI="2, 3, 3+"
				[ -n "$kver" ] && menu=`echo "$MENU7"|grep $kver` || menu="$MENU7";;
				3)PI="4, 4+"
				[ -n "$kver" ] && menu=`echo "$MENU7l"|grep $kver` || menu="$MENU7l";;
			esac
			[ -z "$menu" ] && continue
			echo "Do you want to choose a Raspberry Pi $PI kernel? (y/n)"
			read yesno
			case $yesno in
				y*|Y)echo "Please choose the number of the Raspberry Pi $PI kernel you wish to use";;
				*)let "e += 1"; [ $e -eq 4 ] && break || continue;;
			esac
			echo "$menu"
			read kernel_nr
			menu_item="`echo "$menu" | grep ^$kernel_nr -`"
			[ ! "$menu_item" ] && echo "invalid choice" && continue
			chosen="${menu_item##* }"
			kver=${chosen:11}
			kver=${kver%%[-+]*}
			echo "You chose $chosen which is Linux version $kver"
			case $e in 
				1)CHOSEN_KERNEL="$chosen";;
				2)CHOSEN_KERNEL7="$chosen";;
				3)CHOSEN_KERNEL7L="$chosen";;
			esac
			echo
			let "e += 1"
			[ $e -eq 4 ] && break
		done
	fi
}

mkdir -p ../../local-repositories/${DISTRO_TARGETARCH}/kernels

# precaution
mkdir -p build

#-----------------------------------------

if [ -d '../kernel-kit/output' ];then
	# only look for kernels that match DISTRO_FILE_PREFIX
	KIT_KERNELS=`find ../kernel-kit/output -maxdepth 1 -type f -name "kit-kernel*${DISTRO_FILE_PREFIX}.tar*" |grep -v 'txt$'`
	for ONE_KERNEL in $KIT_KERNELS
	do
		ONE_KERNEL_NAME=${ONE_KERNEL##*/}
		if [ ! -e "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${ONE_KERNEL_NAME}" ]; then
			cp ${ONE_KERNEL} ../../local-repositories/${DISTRO_TARGETARCH}/kernels/
		fi
		if [ ! -e "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${ONE_KERNEL_NAME}.sha256.txt" ]; then
			cp ${ONE_KERNEL}.sha256.txt ../../local-repositories/${DISTRO_TARGETARCH}/kernels/
		fi

	done
fi

if [ "$KERNEL_TARBALL_URL" != "" ]; then
	download_kernel "$KERNEL_TARBALL_URL"
fi

if [ "$KERNEL7_TARBALL_URL" != "" ]; then
	download_kernel "$KERNEL7_TARBALL_URL"
fi

if [ "$KERNEL7L_TARBALL_URL" != "" ]; then
	download_kernel "$KERNEL7L_TARBALL_URL"
fi

if  [ "$KERNEL_TARBALL_URL" = "" -a "$KERNEL7_TARBALL_URL" = "" -a "$KERNEL7L_TARBALL_URL" = "" ]; then
	echo "Do you want to download a kernel?"
	read yesno
	if [ "$yesno" = "yes" -o "$yesno" =  "y" ]; then
		choose_kernel_to_download

		if [ "${DISTRO_TARGETARCH}" = "arm" ]; then
			d=0
			while [ $d -lt 2 ]
			do
				case $d in 
					0) nmbr="second";;
					1) nmbr="third";;
				esac
				echo "Do you want to download a $nmbr kernel?"
				read yesno
				if [ "$yesno" = "yes" -o "$yesno" =  "y" ]; then
					choose_kernel_to_download
				else
					break # no second so don't offer third
				fi
				let "d += 1"
			done
		fi
		# file at $TMP created by choose_kernel_to_download
		rm $TMP
	fi
fi

# "support/kit_kernel.sh download" could be called from 1download
if [ "$1" = "download" ]; then
	exit 0
fi

NR_OF_KERNELS="`ls ../../local-repositories/${DISTRO_TARGETARCH}/kernels/*.tar.xz 2>/dev/null | wc -l`"

if [ "$NR_OF_KERNELS" = "0" ]; then
	echo "ERROR: No kernels found."
	exit 1
elif [ "$NR_OF_KERNELS" = "1" ]; then
	CHOSEN_KERNEL="$(cd ../../local-repositories/${DISTRO_TARGETARCH}/kernels/
	ls *.tar.xz)"
elif [ "$KERNEL_TARBALL_URL" != "" -o "$KERNEL7_TARBALL_URL" != "" -o "$KERNEL7L_TARBALL_URL" != "" ]; then
	[ "$KERNEL_TARBALL_URL" != "" ] && CHOSEN_KERNEL="`name_of "$KERNEL_TARBALL_URL"`"
	[ "$KERNEL7_TARBALL_URL" != "" ] && CHOSEN_KERNEL7="`name_of "$KERNEL7_TARBALL_URL"`"
	[ "$KERNEL7L_TARBALL_URL" != "" ] && CHOSEN_KERNEL7L="`name_of "$KERNEL7L_TARBALL_URL"`"
elif [ "$CHOSEN_KERNEL" = "" -a "$CHOSEN_KERNEL7" = "" -a "$CHOSEN_KERNEL7L" = "" ]; then
	choose_kernel
fi


[ -n "$CHOSEN_KERNEL" ] && echo "Pi 0,1 kernel: $CHOSEN_KERNEL"
[ -n "$CHOSEN_KERNEL7" ] && echo "Pi 2,3 kernel: $CHOSEN_KERNEL7"
[ -n "$CHOSEN_KERNEL7L" ] && echo "Pi 4 kernel: $CHOSEN_KERNEL7L"
cd build
if [ "$CHOSEN_KERNEL" != "" ]; then
	echo "Installing $CHOSEN_KERNEL to build/"
	sleep 1

	tar -xvf "../../../local-repositories/${DISTRO_TARGETARCH}/kernels/${CHOSEN_KERNEL}"
	[ "$?" = 0 ] || exit 1

	if [ "${DISTRO_TARGETARCH}" = "arm" ]; then
		[ -f vmlinuz-*-v7+* ] && mv -f vmlinuz-*-v7* vmlinuz7
		[ -f vmlinuz-* ] && mv -f vmlinuz-* vmlinuz
	else
		[ -f vmlinuz-* ] && mv -f vmlinuz-* vmlinuz
	fi
fi

if [ "${DISTRO_TARGETARCH}" = "arm" -a "$CHOSEN_KERNEL7" != "" ]; then
	echo "Installing $CHOSEN_KERNEL7 to build/"
	sleep 1

	tar -xvf "../../../local-repositories/${DISTRO_TARGETARCH}/kernels/${CHOSEN_KERNEL7}"
	[ "$?" = 0 ] || exit 1

	[ -f vmlinuz-*-v7+* ] && mv -f vmlinuz-*-v7+* vmlinuz7
	[ -f vmlinuz-* ] && mv -f vmlinuz-* vmlinuz
fi

if [ "${DISTRO_TARGETARCH}" = "arm" -a "$CHOSEN_KERNEL7L" != "" ]; then
	echo "Installing $CHOSEN_KERNEL7L to build/"
	sleep 1

	tar -xvf "../../../local-repositories/${DISTRO_TARGETARCH}/kernels/${CHOSEN_KERNEL7L}"
	[ "$?" = 0 ] || exit 1

	[ -f vmlinuz-*-v7l+* ] && mv -f vmlinuz-*-v7l+* vmlinuz7l
	[ -f vmlinuz-* ] && mv -f vmlinuz-* vmlinuz
fi

cd ..

exit 0

### END ###
