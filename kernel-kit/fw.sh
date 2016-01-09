#!/bin/sh
# called from build.sh (kernel-kit)

export LANG=C # faster

[ -f ./build.conf ] && . ./build.conf || exit 1

CWD=`pwd`

[ -f ./fw.log ] && rm ./fw.log


# vars
src_fw_dir='../linux-firmware'
src_fw_src='linux-firmware'
src_file_FW=${src_fw_dir}/WHENCE
src_file_DRV=`find dist/sources -type f -name 'DOTconfig*' -maxdepth 1` #'./DOTconfig'
dest_fw_dir='workdir/lib'
result_dir='workdir/lib/firmware'
not_dir='workdir/lib/linux-firmware'
pkg_dir='dist/packages'
fw_sfs="dist/packages/fdrv_${kernel_version}_${package_name_suffix}.sfs"
kernel_package=`find dist -type d -name 'linux_kernel*'`
dest=${kernel_package}/lib/firmware
src=$result_dir

func_git() {
	if [ -d "$src_fw_dir" ];then
		cd $src_fw_dir
		echo "Updating the git firmware repo"
		git pull
		if [ $? -ne 0 ];then
			echo "Failed to update git firmware" # non fatal
			cd -
		fi
		cd -
	else
		cd ..
		echo "Cloning the firmware repo may take a long time"
		git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
		if [ $? -ne 0 ];then
			echo "Failed to clone the git firmware repo"
			cd -
			return 1
		fi
		cd -
	fi
	return 0
}

get_func() {
	#filter some junk
	echo "$1"|grep -q -E '[a-z]\.[a-z]|[0-9]\.[a-z]|[A-Z]\.[a-z]|RTL' || return # what we want
	echo "$1"|grep -q -E '^Version:|Source:|Info:' && return # PITA
	echo "$1"|grep -q '@' && return # email address
	echo "$1"|grep -q '[0-9]\.p[0-9]' && return # page rubbish
	echo "$1"|grep -q 'https:' && return # wtf??
	echo "$1"|grep -q '\/src' && return # source
	# copy files
	cd ..
	cp -d --parents $src_fw_src/$1 ${CWD}/${dest_fw_dir}/ 2>/dev/null # send to oblivion what wasn't caught above
	ret=$?
	cd $CWD
	if [ $ret -eq 0 ];then
		echo "$1 	`stat -c %s $src_fw_dir/$1`" >> fw.log
	else
		echo "FAILURE: $1" >> fw.log
	fi
}

process_driver() {
	driver=$1
	DRIVER=`echo ${driver^^}|tr '-' '_'`
	case $DRIVER in # try to avoid dups
		RADEON)DRIVER=DRM_RADEON;;
		KEYSPAN)DRIVER='SERIAL_KEYSPAN=';;
		LIBERTAS)DRIVER=LIBERTAS_USB;;
		MWIFIEX)DRIVER=MWIFIEX_USB;;
	esac
	echo -n "$driver "
	D=`grep $DRIVER $src_file_DRV|grep -v -E '^#|is not set$'|head -n1`
	[ -z "$D" ] && return 1
	return 0
}

get_entry() {
	MAX=`wc -l $src_file_FW|cut -d ' ' -f1`
	while read line ; do
		if echo "$line"|grep -q '^Driver:';then
			driver=`echo $line|cut -d ' ' -f2`
			process_driver $driver
			[ $? -ne 0 ] && continue
			if [ "$line" ] ;then
				line_no=`grep -n '^Driver:' $src_file_FW|grep "$driver"|cut -d':' -f1`
				num_entries=`printf "$line_no\n"|wc -l` # sometimes more tha 1 in WHENCE
				case $num_entries in
					1)	line_next=$(($line_no + 1))
						while [ 1 ];do	
							file=`sed "${line_next}q;d" $src_file_FW` 2>&1 >/dev/null
							echo "$file"|grep -q -E '^Licence|License' && run=0 && break
							file=`echo $file|awk '{print $2}'`
							get_func $file
							line_next=$(($line_next + 1))
							[ $line_next -gt $MAX ] && return # precaution
						done
						;;
					[2-9])for i in $line_no; do
							line_next=$(($i + 1))
							while [ 1 ];do
								file=`sed "${line_next}q;d" $src_file_FW` 2>&1 >/dev/null
								echo "$file"|grep -q -E '^Licence|License' && run=0 && break
								file=`echo $file|awk '{print $2}'`
								get_func $file
								line_next=$(($line_next + 1))
								[ $line_next -gt $MAX ] && return # precaution
							done
						done
						;;
				esac
			fi
		fi
	done < $src_file_FW
}

fw_filter(){
	list=$1
	echo "Filtering with $list"
	echo 'FILTERED FIRMWARE LIST IN ZDRV' > ${list}.log
	echo '==============================' >> ${list}.log
	mkdir -p $result_dir
	while read line; do
		file=${line##*/}
		file_path=`find ${not_dir} -name $file|head -n1`
		[ -z "$file_path" ] && continue
		nfile_path=`echo $file_path|sed "s%${not_dir}\/%%"` # strip leading crap
		retrieve_path=${not_dir}/${nfile_path}
		retrieve_dir=${retrieve_path%/*} # strip off file
		if echo ${nfile_path} | grep -q '\/';then # in a subdir
			if test ! -d "${result_dir}/${nfile_path%/*}";then # manufacture dest subdirs before move
				path=${nfile_path%/*}
				mkdir -p ${result_dir}/${path}
			fi
			mv -f ${retrieve_dir}/${file} ${result_dir}/${path}/
			[ $? -eq 0 ] && echo "${file} SUCCESS" >> ${list}.log || echo "${file} FAIL" >> ${list}.log
		else
			mv -f ${retrieve_dir}/${file} ${result_dir}/
			[ $? -eq 0 ] && echo "${file} SUCCESS" >> ${list}.log || echo "${file} FAIL" >> ${list}.log
		fi
	done < $list
}

licence_func () {
	echo "Extracting licences"
	mkdir -p ${result_dir}/licences
	find ${src_fw_dir} -type f -iname 'licen?e*' -exec cp '{}' ${result_dir}/licences \;
}

# update or clone git firmware
func_git
[ $? -ne 0 ] && echo "Aborting." && exit 1

[ -d "$dest_fw_dir" ] && rm -r "$dest_fw_dir"
mkdir -p "$dest_fw_dir"
[ -f "$fw_sfs" ] && rm $fw_sfs

# process entries in WHENCE
echo "Extracting firmware"
get_entry
echo

# cut down firmware .. or not
fw_flag=$1
case $fw_flag in
	big)echo="Not filtering"
		mv $not_dir ${result_dir}
		licence_func
		cp -n -r ${src}/* ${dest}/
		SFS=ZDRV
		;;
	  *)fw_filter firmware.lst
	    find $not_dir -type d -empty -delete
	    licence_func
	    # copy final fw to kernel
		cp -n -r ${src}/* ${dest}/
	    rm -r ${src}
		# now move the extras to / lib/firmware & make sfs
		mv $not_dir ${src}
	    mksquashfs workdir $fw_sfs -comp xz
	    md5sum $fw_sfs > ${fw_sfs}.md5.txt
		SFS=FDRV
		;;
esac

echo '================' >> build.log
echo "FIRMWARE IN $SFS" >> build.log
echo '================' >> build.log
cat fw.log >> build.log
echo '==============================' >> build.log
[ -f ${list}.log ] && cat ${list}.log >> build.log && rm ${list}.log
# cleanup
rm fw.log
rm -r workdir


echo "Firmware script complete."
exit 0
