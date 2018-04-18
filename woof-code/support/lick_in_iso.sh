#!/bin/sh
# * called by 3builddistro
# * we're in sandbox3
# * install lick to build/

L_URL='https://github.com/noryb009/lick/releases/download/v1.3/LICK-1.3.0-win32.zip'
L_FILE=${L_URL##*/} #basename $L_URL

mkdir -p ../../local-repositories #precaution
rm -rf build/Windows_Installer

if [ ! -f ../../local-repositories/${L_FILE} ] ; then
	wget -P ../../local-repositories/ -c $L_URL
	if [ $? -eq 0 ] ; then
		(
			cd ../../local-repositories/
			md5sum -b ${L_FILE} > ${L_FILE}.md5.txt
		)
	else
		echo "ERROR downloading LICK"
		rm -f ../../local-repositories/${L_FILE}
		rm -rf build/Windows_Installer
		exit 1
	fi
fi

if [ ../../local-repositories/${L_FILE}.md5.txt ] ; then
	( cd ../../local-repositories/ ; md5sum -c ${L_FILE}.md5.txt )
fi

mkdir -p build/Windows_Installer
cp -fv ../../local-repositories/${L_FILE} build/Windows_Installer/
sleep 1
echo

cat <<EOF>> build/Windows_Installer/README.TXT
You can use LICK, by Luke Lorimer <noryb009>,
to install this Puppy from Windows without the need
of a CD, USB or a Linux partition. Just extract the
LICK-1.3.0-win32.zip archive in windows and
follow the instructions in README.txt within the
LICK-1.3.0-win32 folder.
When prompted chose this ISO image for installation.

You can find the latest LICK version and code in
https://github.com/noryb009/lick and further
documentation by Luke Lorimer in
https://csclub.uwaterloo.ca/~lalorime/lick/doc/index.html
and forum support and discussion in
http://murga-linux.com/puppy/viewtopic.php?t=61404
EOF

