#!/bin/sh
# - this script is to ensure a puppy always works properly
#   even when the gettext.sh script is not present or has been deleted
# - some people might not want to use gettext at all
# - scripts may be faster by using this

# GUI scripts have "\Z" and \ is lost after eval
#   so there's a workaround for that

# Scripts use arguments with more than one line
#   eval tries to execute the 2nd line and so on
#   to fix this, pass a variable without ""
#   as that method passes spaces instead of lines

eval_gettext() {
	msg="$1"
	[ "$msg" ] || return 1
	#Convert "\Z" to "~Z"
	msg="${msg//\\\Z/~Z}"
	# Eval
	msg="$(eval echo -n $msg)"
	#Convert "~Z" to "\Z"
	msg="${msg//~Z/\\\Z}"
	#deliver msg
	echo "$msg"
}

# needs 3-4 arguments
eval_ngettext () {
	msg=
	[ "$5" ] && return 1
	if [ "$4" ] ; then
		msg="$3"
	elif [ "$3" ] ; then
		msg="$2"
	fi
	[ "$msg" ] || return 1
	msg="$1"
	#Convert "\Z" to "~Z"
	msg="${msg//\\\Z/~Z}"
	# Eval
	msg="$(eval echo -n $msg)"
	#Convert "~Z" to "\Z"
	msg="${msg//~Z/\\\Z}"
	#deliver msg
	echo "$msg"
}

gettext() {
	echo -n "$@"
}

ngettext() {
	[ "$5" ] && return 1
	if [ "$4" ] ; then
		echo -n "$3" ; return
	elif [ "$3" ] ; then
		echo -n "$2" ; return
	fi
	return 1
}

### END ###
