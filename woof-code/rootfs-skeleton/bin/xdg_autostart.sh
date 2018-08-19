#!/bin/sh

#set -x

verify_not_running() {
	while read j
	do
		case $j in "Name="*|"Exec="*)
			name="${j#Name=}"
			name="${name#Exec=}"
			name="${name#sh -c }"
			name="${name//\'/}"
			name="${name//\"/}"
			name="${name%% *}"
			case $name in echo|sleep) #add more
				return 0
				break
			esac
			if pidof "$name" &>/dev/null ; then
				return 1
				break
			fi
			;;
		esac
	done < "$1"
	return 0
}

#=================================================

for i in $HOME/.config/autostart/*.desktop
do
	if ! [ -f $i ] ; then
		continue
	fi
	if ! verify_not_running $i ; then
		continue
	fi
	xdg-open $i
done

#=================================================

for i in /etc/xdg/autostart/*.desktop
do
	if ! [ -f $i ] ; then
		continue
	fi
	if [ -f $HOME/.config/autostart/${i} ] ; then
		continue
	fi
	if ! verify_not_running $i ; then
		continue
	fi
	xdg-open $i
done

### END ###