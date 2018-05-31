#!/bin/bash
# jamesbond 2011
# required: bash v4, gawk, xrandr 1.3
# version 1 - august 2011

APPNAME=Zoom

### populate variables with info about current xrandr state
load_info() {
	xrandr | awk ' 
function output() {
	print "DISP_NAME=\"" display "\""
	print "DISP_LIST[" counter "]=\"" display "\"" 
	print "DISP[\"${DISP_NAME}_state\"]=\"" state "\""
	print "DISP[\"${DISP_NAME}_panning\"]=\"" panning "\""
	print "DISP[\"${DISP_NAME}_current\"]=\"" current "\""
	print "DISP[\"${DISP_NAME}_res\"]=\"" res "\""
}	
BEGIN {counter=0;}
{
	if ($2 ~ /connected/) {
		# if this is not the first time, store values from previous run
		if (counter > 0) {
			output();
		} 
		counter += 1;	
		
		# begin new display
		display=$1;
		state=$2;
		res=""
		current=""
		panning=""
		if ($0 ~ /panning/) {
			sub(/\+.*/,"",$NF);
			panning=$NF;
		}
	} else if (counter > 0) {
		res = $1 " " res
		if ($2 ~ /\*/) current=$1
	}
}
END {
	output(); 
}' > /tmp/zoom_vars
#cat /tmp/zoom_vars
. /tmp/zoom_vars
rm /tmp/zoom_vars
} 

connected_displays() {
	for a in ${DISP_LIST[@]}; do
		if [ ${DISP[${a}_state]} = "connected" ]; then echo $a; fi
	done
	#echo HDMI-0  ### TEST
}

zoomed_displays() {
	#1 get list of connected displays
	CONNECTED=($(connected_displays))

	#2 for each one of these, see which one is currently zoomed ("panning" is not empty)
	for a in ${CONNECTED[@]}; do
		if [  -n "${DISP[${a}_panning]}" ]; then echo $a; fi
	done
	#echo HDMI-0 ### TEST
}

choose_items() {
	ITEMS=""
	for a in $@; do ITEMS="$ITEMS $a \"\"" ;done
	eval "Xdialog --stdout --title \"$APPNAME\" --menubox \"$TEXT\" 0 0 5 $ITEMS"
}

message() {
	Xdialog --title "$APPNAME" --msgbox "$1" 0 0 
}

zoom_in() {	
	#1 get list of connected displays
	CONNECTED=($(connected_displays))
	echo Connected: ${CONNECTED[@]}
	
	#2 let user choose - if there is only one, select automatically
	if (( ${#CONNECTED[@]} > 1)); then
		CHOSEN=$(TEXT="Choose display to zoom" choose_items "${CONNECTED[@]}")
	else
		CHOSEN=$CONNECTED
	fi
	echo Chosen: $CHOSEN
	if [ "$CHOSEN" = "" ]; then return; fi  # if none chosen, quit
	
	#3 if that display is not already zoomed, let user choose the resolution
	#DISP[${CHOSEN}_panning]=""
	if [  -n "${DISP[${CHOSEN}_panning]}" ]; then
		message "$CHOSEN already zoomed"
		return
	else
		RES=$(TEXT="Choose resolution" choose_items ${DISP[${CHOSEN}_res]})
		echo Resolution: $RES
	fi
	if [ "$RES" = "" ]; then return; fi # if none chosen, quit
	
	#4 do it
	xrandr --output $CHOSEN --mode $RES --panning ${DISP[${CHOSEN}_current]}
}

zoom_out() {
	#1 get list of zoomed displays
	ZOOMED=($(zoomed_displays))
	echo Zoomed: ${ZOOMED[@]}
	
	#2 if there is only one active zoom, use that, otherwise let user choose
	if (( ${#ZOOMED[@]} < 1)); then message "Nothing to zoom out"; return; fi
	if (( ${#ZOOMED[@]} > 1)); then
		CHOSEN=$(TEXT="Choose display to un-zoom" choose_items "${ZOOMED[@]}")
	else
		CHOSEN=$ZOOMED
	fi
	echo Chosen: $CHOSEN
	if [ "$CHOSEN" = "" ]; then return; fi  # if none chosen, quit
	
	#3 do it
	xrandr --output $CHOSEN --mode ${DISP[${CHOSEN}_panning]} --panning 0x0
}

zoom_toggle() {
	ZOOMED=($(zoomed_displays))
	
	# if there are zoomed displays, go to zoom-out otherwise zoom-in
	if (( ${#ZOOMED[@]} > 0)); then 
		zoom_out
	else
		zoom_in
	fi
}

###### main program entry point ######
declare -A DISP
load_info
case "$1" in
	in)
		zoom_in
		;;
	out)
		zoom_out
		;;
	toggle | "")
		zoom_toggle
		;;
	*)
		echo "Usage: $0 [in|out|toggle]."
		echo "Toggle is default if no parameter is given."
		;;
esac