#!/bin/sh
#y = builtin
#m = module

function pause() {
	echo -n "Press enter to continue..."
	read zzz
}

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

function set_pae() {
	#http://askubuntu.com/questions/395771/in-32-bit-ubuntu-12-04-how-can-i-find-out-if-pae-has-been-enabled
	config_set builtin CONFIG_X86_PAE $1
	config_set builtin CONFIG_HIGHMEM64G $1
	config_unset CONFIG_HIGHMEM4G $1
}

function unset_pae() {
	config_delete CONFIG_X86_PAE $1
	config_unset CONFIG_HIGHMEM64G $1
	config_set builtin CONFIG_HIGHMEM4G $1
}

#$@

### END ###
