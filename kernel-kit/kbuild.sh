#!/bin/sh -xe

for FILE in tools scripts Makefile include .config Module.symvers; do
	cp -a ${1}/${FILE} ${2}/
done

find ${1}/arch -name Makefile -or -name include |
while read FILE; do
	DIR=`dirname ${FILE}`
	DIR=${DIR#${1}/}
	mkdir -p ${2}/${DIR}
	cp -a ${FILE} ${2}/${DIR}
done