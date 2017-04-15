#!/bin/bash
#y = builtin
#m = module

function pause() {
	echo -n "Press enter to continue..."
	read zzz
}

function log_ver() {
	touch ${BUILD_LOG}
	(
	if [ -f /etc/DISTRO_SPECS ] ; then
		. /etc/DISTRO_SPECS
		echo "$DISTRO_NAME $DISTRO_VERSION [$(uname -m)]"
	fi
	gcc --version | head -1
	git --version | head -1
	mksquashfs -version | head -1
	echo
	) | tee -a ${BUILD_LOG}
}

#======================================================================

function config_is_set() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	if grep -q -E "^${opt}=y|^${opt}=m" "$file" ; then
		return 0
	else
		return 1
	fi
}

# $1 = type
# $2 = config_opt
# $3 = config_file
function config_set() {
	[ ! "$1" -o ! "$2" -o ! "$3" ] && return 1
	local type=$1 opt=$2 file=$3 t
	case $type in
		builtin) t='y' ;;
		custom) t='c' ;; #for special purposes (further processing)
		*) t='m' ;; #module = default
	esac
	sed -i -e "s|# $opt .*|${opt}=${t}|" \
		-e "s|^$opt=.*|${opt}=${t}|" "$file"
}

function config_unset() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	sed -i -e "s|^${opt}=y|# $opt is not set|" \
		-e "s|^${opt}=m|# $opt is not set|" "$file"
}

function config_toggle() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	if config_is_set $opt "$file" ; then
		config_unset $opt "$file"
	else
		config_set module $opt "$file"
	fi
}

function config_delete() {
	[ ! "$1" -o ! "$2" ] && return
	local opt=$1 file=$2
	sed -i -e "/^${opt}=y/d" -e "/ ${opt} /d" "$file"
}

# $1 = config file
function config_get_builtin()   { grep '=y'  "$1" | cut -f1 -d '=' ; }
function config_get_module()   {  grep '=m'  "$1" | cut -f1 -d '=' ; }
function config_get_set() { grep -E '=m|=y'  "$1" | cut -f1 -d '=' ; }
function config_get_unset() { grep 'not set' "$1" | cut -f2 -d ' ' ; }

# $1 = config_file
# $2 = file with fixed config options
function fix_config() {
	[ ! "$1" -o ! "$2" ] && return
	local file=$1 fixed_opts=$2
	(
	cat $fixed_opts | sed -e 's| is not set||' -e '/^$/d' -e '/##/d' | \
	while read line ; do
		case $line in
			*'=m') C_OPT=${line%=*} ; echo "s%.*${C_OPT}.*%${C_OPT}=m%" ;;
			*'=y') C_OPT=${line%=*} ; echo "s%.*${C_OPT}.*%${C_OPT}=y%" ;;
			*) C_OPT=${line:2}      ; echo "s%.*${C_OPT}.*%# ${C_OPT} is not set%" ;;
		esac
	done
	) > /tmp/ksed.file
	cp "$1" "$1".orig
	sed -i -f /tmp/ksed.file "$1"
}


##############
## EXAMPLES ##
##############

# $1: kernel config file
function set_pae() {
	#http://askubuntu.com/questions/395771/in-32-bit-ubuntu-12-04-how-can-i-find-out-if-pae-has-been-enabled
	config_set builtin CONFIG_X86_PAE $1
	config_set builtin CONFIG_HIGHMEM64G $1
	config_unset CONFIG_HIGHMEM4G $1
}

# $1: kernel config file
function unset_pae() {
	config_delete CONFIG_X86_PAE $1
	config_unset CONFIG_HIGHMEM64G $1
	config_set builtin CONFIG_HIGHMEM4G $1
}

# $1: kernel config file
function set_i486() {
	config_set builtin CONFIG_M486 $1
	for i in CONFIG_M386 CONFIG_M686 CONFIG_M586 CONFIG_M586TSC CONFIG_M586MMX CONFIG_MPENTIUMII CONFIG_MPENTIUMIII CONFIG_MPENTIUMM CONFIG_MPENTIUM4 CONFIG_MK6 CONFIG_MK7 CONFIG_MK8 CONFIG_MCRUSOE CONFIG_MEFFICEON CONFIG_MWINCHIPC6 CONFIG_MWINCHIP3D CONFIG_MELAN CONFIG_MGEODEGX1 CONFIG_MGEODE_LX CONFIG_MCYRIXIII CONFIG_MVIAC3_2 CONFIG_MVIAC7 CONFIG_MCORE2 CONFIG_MATOM
	do
		config_unset $i $1
	done
}

# $1: kernel config file
function set_i686() {
	config_set builtin CONFIG_M686 $1
	for i in CONFIG_M386 CONFIG_M486 CONFIG_M586 CONFIG_M586TSC CONFIG_M586MMX CONFIG_MPENTIUMII CONFIG_MPENTIUMIII CONFIG_MPENTIUMM CONFIG_MPENTIUM4 CONFIG_MK6 CONFIG_MK7 CONFIG_MK8 CONFIG_MCRUSOE CONFIG_MEFFICEON CONFIG_MWINCHIPC6 CONFIG_MWINCHIP3D CONFIG_MELAN CONFIG_MGEODEGX1 CONFIG_MGEODE_LX CONFIG_MCYRIXIII CONFIG_MVIAC3_2 CONFIG_MVIAC7 CONFIG_MCORE2 CONFIG_MATOM
	do
		config_unset $i $1
	done
}

# $HOST_ARCH and $x86_* are set in build.conf and/or build.sh
# edits .config in current dir
# part of build.sh ...
function i386_specific_stuff() {
	if [ "$HOST_ARCH" = "x86" ] ; then
		if [ "$x86_disable_pae" = "yes" ] ; then
			if grep 'CONFIG_X86_PAE=y' .config ; then #CONFIG_HIGHMEM64G=y
				log_msg "Disabling PAE..."
				MAKEOLDCONFIG=1
				unset_pae .config
			fi
		fi
		if [ "$x86_enable_pae" = "yes" ] ; then
			if ! grep 'CONFIG_X86_PAE=y' .config ; then
				log_msg "Enabling PAE..."
				MAKEOLDCONFIG=1
				set_pae .config
			fi
		fi
		if [ "$x86_set_i486" = "yes" ] ; then
			if grep -q 'CONFIG_OUTPUT_FORMAT="elf32-i386"' .config ; then
				if ! grep -q 'CONFIG_M486=y' .config ; then
					log_msg "Forcing i486..."
					MAKEOLDCONFIG=1
					set_i486 .config
				fi
			fi
		fi
		if [ "$x86_set_i686" = "yes" ] ; then
			if grep -q 'CONFIG_OUTPUT_FORMAT="elf32-i386"' .config ; then
				if ! grep -q 'CONFIG_M686=y' .config ; then
					log_msg "Forcing i686..."
					MAKEOLDCONFIG=1
					set_i686 .config
				fi
			fi
		fi
		[ "$MAKEOLDCONFIG" != "" ] && make silentoldconfig
	fi
}

#$@

### END ###
