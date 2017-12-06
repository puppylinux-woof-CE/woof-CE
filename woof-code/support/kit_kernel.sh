#!/bin/bash
# install kit kernel to build
# * called by 3builddistro
# * can be run independently
# * we're in sandbox3

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
	local URL="$1" TARBALL_NAME="`name_of "$URL"`"
	wget -t0 -c $URL -P ../../local-repositories/${DISTRO_TARGETARCH}/kernels
	wget ${URL}.sha256.txt -P ../../local-repositories/${DISTRO_TARGETARCH}/kernels

	if [ -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${TARBALL_NAME}.sha256.txt" ]; then
		( cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
		sha256sum -c "${TARBALL_NAME}.sha256.txt") &> /dev/null
		if [ "$?" != "0" ]; then
			echo "ERROR: checksum failed, $TARBALL_NAME"
			echo "located at `realpath ../../local-repositories/${DISTRO_TARGETARCH}/kernels/`"
			exit 1
		fi
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

	if [ "$KIT_KERNEL_REPO_URL" != "${KIT_KERNEL_REPO_URL/github.com/}" ]; then
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
	if [ "$THIS_KERNEL" != "${THIS_KERNEL/-v7/}" ]; then
		CHOSEN_KERNEL7="$THIS_KERNEL"
	else
		CHOSEN_KERNEL="$THIS_KERNEL"
	fi
}

choose_kernel() {
	local MENU="$(cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
	I=1
	for ONE_KERNEL in kit-kernel-*.tar.xz
	do
		echo "$I $ONE_KERNEL"
		let "I += 1"
	done
	)"
	while [ 1 ]
	do
		echo
		echo "Please choose the number of the kernel you wish to use"
		echo "$MENU"
		read kernel_nr
		menu_item="`echo "$MENU" | grep ^$kernel_nr -`"
		[ ! "$menu_item" ] && echo "invalid choice" && continue
		CHOSEN_KERNEL="${menu_item##* }"
		echo "You chose $CHOSEN_KERNEL"
		break
	done
	if [ "${DISTRO_TARGETARCH}" = "arm" ]; then
		local MENU7="$(cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
		I=1
		for ONE_KERNEL in kit-kernel-*-v7*.tar.xz
		do
			echo "$I $ONE_KERNEL"
			let "I += 1"
		done
		)"
		local MENU_NOT_7="$(cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
		I=1
		for ONE_KERNEL in kit-kernel-*.tar.xz
		do
			if [ "`echo "$MENU7" | grep "$ONE_KERNEL" -`" = "" ]; then
				echo "$I $ONE_KERNEL"
				let "I += 1"
			fi
		done
		)"
		if [ "$CHOSEN_KERNEL" != "${CHOSEN_KERNEL/-v7/}" ]; then
			CHOSEN_KERNEL7="$CHOSEN_KERNEL"
			CHOSEN_KERNEL=""

			if [ "$MENU_NOT_7" != "" ]; then
				echo "Do you want to choose a second kernel?"
				read yesno
				if [ "$yesno" = "yes" -o "$yesno" =  "y" ]; then
					while [ 1 ]
					do
						echo
						echo "Please choose the number of the kernel you wish to use"
						echo "$MENU_NOT_7"
						read kernel_nr
						menu_item="`echo "$MENU_NOT_7" | grep ^$kernel_nr -`"
						[ ! "$menu_item" ] && echo "invalid choice" && continue
						CHOSEN_KERNEL="${menu_item##* }"
						echo "You chose $CHOSEN_KERNEL"
						break
					done
				fi
			fi
		else
			if [ "$MENU7" != "" ]; then
				echo "Do you want to choose a second kernel?"
				read yesno
				if [ "$yesno" = "yes" -o "$yesno" =  "y" ]; then
					while [ 1 ]
					do
						echo
						echo "Please choose the number of the kernel you wish to use"
						echo "$MENU7"
						read kernel_nr
						menu_item="`echo "$MENU7" | grep ^$kernel_nr -`"
						[ ! "$menu_item" ] && echo "invalid choice" && continue
						CHOSEN_KERNEL7="${menu_item##* }"
						echo "You chose $CHOSEN_KERNEL7"
						break
					done
				fi
			fi
		fi

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
	TARBALL_NAME="`name_of "$KERNEL_TARBALL_URL"`"
	if [ -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${TARBALL_NAME}" ]; then
		if [ -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${TARBALL_NAME}.sha256.txt" ]; then
			( cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
			sha256sum -c "${TARBALL_NAME}.sha256.txt") &> /dev/null
			if [ "$?" != "0" ]; then
				download_kernel "$KERNEL_TARBALL_URL"
			fi
		fi
	else
		download_kernel "$KERNEL_TARBALL_URL"
	fi
fi

if [ "$KERNEL7_TARBALL_URL" != "" ]; then
	TARBALL_NAME="`name_of "$KERNEL7_TARBALL_URL"`"
	if [ -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${TARBALL_NAME}" ]; then
		if [ -f "../../local-repositories/${DISTRO_TARGETARCH}/kernels/${TARBALL_NAME}.sha256.txt" ]; then
			( cd "../../local-repositories/${DISTRO_TARGETARCH}/kernels/"
			sha256sum -c "${TARBALL_NAME}.sha256.txt") &> /dev/null
			if [ "$?" != "0" ]; then
				download_kernel "$KERNEL7_TARBALL_URL"
			fi
		fi
	else
		download_kernel "$KERNEL7_TARBALL_URL"
	fi
fi

if  [ "$KERNEL_TARBALL_URL" = "" -a "$KERNEL7_TARBALL_URL" = "" ]; then
	echo "Do you want to download a kernel?"
	read yesno
	if [ "$yesno" = "yes" -o "$yesno" =  "y" ]; then
		choose_kernel_to_download

		if [ "${DISTRO_TARGETARCH}" = "arm" ]; then
			echo "Do you want to download a second kernel?"
			read yesno
			if [ "$yesno" = "yes" -o "$yesno" =  "y" ]; then
				choose_kernel_to_download
			fi
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
elif [ "$KERNEL_TARBALL_URL" != "" -o "$KERNEL7_TARBALL_URL" != "" ]; then
	[ "$KERNEL_TARBALL_URL" != "" ] && CHOSEN_KERNEL="`name_of "$KERNEL_TARBALL_URL"`"
	[ "$KERNEL7_TARBALL_URL" != "" ] && CHOSEN_KERNEL7="`name_of "$KERNEL7_TARBALL_URL"`"
elif [ "$CHOSEN_KERNEL" = "" -a "$CHOSEN_KERNEL7" = "" ]; then
	choose_kernel
fi


cd build

if [ "$CHOSEN_KERNEL" != "" ]; then
	echo "Installing $CHOSEN_KERNEL to build/"
	sleep 1

	tar -xvf "../../../local-repositories/${DISTRO_TARGETARCH}/kernels/${CHOSEN_KERNEL}"
	[ "$?" = 0 ] || exit 1

	if [ "${DISTRO_TARGETARCH}" = "arm" ]; then
		[ -f vmlinuz-*-v7* ] && mv -f vmlinuz-*-v7* vmlinuz7
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

	[ -f vmlinuz-*-v7* ] && mv -f vmlinuz-*-v7* vmlinuz7
	[ -f vmlinuz-* ] && mv -f vmlinuz-* vmlinuz
fi

cd ..

exit 0

### END ###
