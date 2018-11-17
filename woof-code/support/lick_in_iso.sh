#!/bin/sh
# * called by 3builddistro
# * we're in sandbox3
# * install lick to build/

README=LICK-1.3.1-win32/README.txt
L_URL='https://github.com/noryb009/lick/releases/download/v1.3.1/LICK-1.3.1-win32.zip'
L_FILE=${L_URL##*/} #basename $L_URL

mkdir -p ../../local-repositories #precaution
rm -rf build/Windows_Installer

if [ ! -f ../../local-repositories/${L_FILE} ] ; then
	wget -P ../../local-repositories/ -c $L_URL
	if [ $? -ne 0 ] ; then
		echo "ERROR downloading LICK"
		rm -f ../../local-repositories/${L_FILE}
		rm -rf build/Windows_Installer
		exit 1
	fi
fi

mkdir -p build/Windows_Installer
cp -fv ../../local-repositories/${L_FILE} build/Windows_Installer/

(
	cd build/Windows_Installer
	unzip -j ${L_FILE} ${README}
)

