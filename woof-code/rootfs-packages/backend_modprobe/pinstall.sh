#!/bin/sh
if [ "$(pwd)" = '/' ];then
	rm -f etc/udev/rules.d/60-dialup-modem.rules #not supported
fi