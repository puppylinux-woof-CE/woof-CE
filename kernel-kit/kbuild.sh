#!/bin/sh -xe

for FILE in tools scripts Makefile include .config Module.symvers; do
	cp -a ${1}/${FILE} ${2}/
done

rm -rf ${2}/tools/perf ${2}/tools/testing

find ${1}/arch/${3} -name Makefile -or -name include |
while read FILE; do
	DIR=`dirname ${FILE}`
	DIR=${DIR#${1}/}
	mkdir -p ${2}/${DIR}
	cp -a ${FILE} ${2}/${DIR}
done