#!/bin/sh
# download and verify files
#
# $1: url
# $2: download location
# $3: copy file to $3
#

CURDIR=${PWD}

URL="$1"
DOWNLOAD_DIR="$2/"
COPYTO="$3"

FILE="${URL##*/}"     # basename
FILE="${FILE//%2B/+}" # un-escape '+'

#==============================================================

if [ ! -f ${DOWNLOAD_DIR}"${FILE}" ] ; then
	mkdir -p ${DOWNLOAD_DIR}
	if [ -f "$URL" ] ; then # full path
		cp -a "$URL" "${FILE}"
	else
		case "$URL" in
		file://*)
			FPATH="${URL#file://}"
			cp -f "${FPATH}" ${DOWNLOAD_DIR}/ || exit 1
			;;

		*)
			wget -P ${DOWNLOAD_DIR} --no-check-certificate "${URL}"
			if [ $? -ne 0 ] ; then
				rm -fv ${DOWNLOAD_DIR}"${FILE}"
				exit 1
			fi
			;;
		esac
	fi
fi

if [ ! -f ${DOWNLOAD_DIR}"${FILE}" ] ; then
	exit 1
fi

if [ ! -f ${DOWNLOAD_DIR}"${FILE}".sha256.txt ] ; then
	wget -P ${DOWNLOAD_DIR} --no-check-certificate "${URL}".sha256.txt 2>/dev/null
	[ $? -ne 0 ] && rm -f ${DOWNLOAD_DIR}"${FILE}".sha256.txt
fi

if [ ! -f ${DOWNLOAD_DIR}"${FILE}".sha256.txt ] ; then
	if [ ! -f ${DOWNLOAD_DIR}"${FILE}".md5.txt ] ; then
		wget -P ${DOWNLOAD_DIR} --no-check-certificate "${URL}".md5.txt 2>/dev/null
		[ $? -ne 0 ] && rm -f ${DOWNLOAD_DIR}"${FILE}".md5.txt
	fi
fi

#==============================================================

if [ ! -f ${DOWNLOAD_DIR}"${FILE}".sha256.txt ] && [ ! -f ${DOWNLOAD_DIR}"${FILE}".md5.txt ] ; then
	echo
	echo "*** No checksum found for $FILE"
	echo "*** Download was successful, so creating checksum..."
	echo
	[ "${DOWNLOAD_DIR}" ] && cd "${DOWNLOAD_DIR}"
	sha256sum "${FILE}" > "${FILE}".sha256.txt
	[ "${DOWNLOAD_DIR}" ] && cd "$CURDIR"
fi

if [ -f ${DOWNLOAD_DIR}"${FILE}".sha256.txt ] ; then
	[ "${DOWNLOAD_DIR}" ] && cd "${DOWNLOAD_DIR}"
	if ! sha256sum -c "${FILE}".sha256.txt ; then
		echo
		echo "*** ERROR: checksum failed, $FILE"
		echo "*** located at $PWD"
		echo
		rm -f "${FILE}" "${FILE}".sha256.txt "${FILE}".md5.txt
		exit 1
	fi
	[ "${DOWNLOAD_DIR}" ] && cd "$CURDIR"
fi

if [ -f ${DOWNLOAD_DIR}"${FILE}".md5.txt ] ; then
	[ "${DOWNLOAD_DIR}" ] && cd "${DOWNLOAD_DIR}"
	if ! md5sum -c "${FILE}".md5.txt ; then
		echo
		echo "*** ERROR: checksum failed, $FILE"
		echo "*** located at $PWD"
		echo
		rm -f "${FILE}" "${FILE}".md5.txt
		exit 1
	fi
	[ "${DOWNLOAD_DIR}" ] && cd "$CURDIR"
fi

#==============================================================

if [ "${COPYTO}" ] ; then
	cp -fv ${DOWNLOAD_DIR}"${FILE}" ${COPYTO}
fi

exit 0
