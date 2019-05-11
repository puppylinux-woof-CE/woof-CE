#!/bin/sh
#
# build from start to finish
# 
# this will consume lots of bandwidth and resources
#
# think about who pays the server bills before running this
#

if [ ! -f ./WOOFMERGEVARS ] ; then
	echo "run merge2out"
	exit 1
fi

# run helper scripts and log the output (script.log)

./xlog 0setup a             #requires a param or ENTER the 2nd time you run it
./xlog 1download            #[pkg]
./xlog 2createpackages -all #or pkg
./xlog 3builddistro-Z
