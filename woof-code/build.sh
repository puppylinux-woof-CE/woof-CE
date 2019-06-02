#!/bin/sh
#
# build from start to finish
# 
# this will consume lots of bandwidth and resources
#
# think about who pays the server bills before running this
#
# build.sh [n]
#   n=0: start from 0setup
#   n=1: start from 1download
#   n=2: start from 2createpackages
#   n=3: start from 3buildistro-Z
#

if [ ! -f ./WOOFMERGEVARS ] ; then
	echo "run merge2out"
	exit 1
fi

for i in $@ ; do
	case $i in
		-release|release) RELEASE=release ; shift ;;
	esac
done

# run helper scripts and log the output (script.log)

case $1 in
0|"")
	./xlog 0setup a             #requires a param or ENTER the 2nd time you run it
	./xlog 1download            #[pkg]
	./xlog 2createpackages -all #or pkg
	./xlog 3builddistro-Z ${RELEASE}
	;;
1)
	./xlog 1download            #[pkg]
	./xlog 2createpackages -all #or pkg
	./xlog 3builddistro-Z ${RELEASE}
	;;
2)
	./xlog 2createpackages -all #or pkg
	./xlog 3builddistro-Z ${RELEASE}
	;;
3)
	./xlog 3builddistro-Z ${RELEASE}
	;;
esac
