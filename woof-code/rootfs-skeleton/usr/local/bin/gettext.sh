#!/bin/sh
# - this script is to ensure a puppy always works properly
#   even when the gettext.sh script is not present or has been deleted
# - some people might not want to use gettext at all
# - scripts may be faster by using this

eval_gettext () {
	eval echo -n "$1"
}

# needs 3-4 arguments
eval_ngettext () {
	[ "$5" ] && return 1
	if [ "$4" ] ; then
		eval echo -n "$3"
	elif [ "$3" ] ; then
		eval echo -n "$2"
	fi
}

### END ###