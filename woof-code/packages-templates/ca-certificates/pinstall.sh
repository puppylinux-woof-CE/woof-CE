#!/bin/sh
# woof pinstall.sh for ca-certificates compat pkg
(
	cd ./usr/share/ca-certificates
	find -type f | cut -c 3- > ../../../etc/ca-certificates.conf
)
chroot . /usr/sbin/update-ca-certificates --fresh
