#!/bin/sh
#(c) copyright Raul Suarez 2006 
#Puppy ndiswrapper GUI setup script.
## updated by Dougal, November 20th 2007
# Update: Sep. 16th 2008: replace all `` subshells with $()
# Update: Oct. 5th:  rewrite selectDriverFile using gtkdialog
# Update: Oct. 10th: add safeguards in case PREV_LOCATION is blank
# Update: Oct. 11th: fix the "ok" of the chooser exit...
# Update: Oct. 26th: localize

#=============================================================================
#============= FUNCTIONS USED IN THE SCRIPT ==============
#=============================================================================

selectDriverFile()
{
  while true ; do
    export NETWIZ_Ndiswrapper_Chooser="<window title=\"$L_TITLE_Netwiz_Ndiswrapper\" icon-name=\"gtk-network\" window-position=\"1\">
<vbox>
  <pixmap><input file>$BLANK_IMAGE</input></pixmap>
  <text>
    <label>\"$L_TEXT_Ndiswrapper_Chooser\"</label>
  </text>
  <pixmap><input file>$BLANK_IMAGE</input></pixmap>
  <chooser>
    <height>300</height><width>550</width>
    <variable>INF_FILE_NAME</variable>
    <default>$PREV_LOCATION</default>
  </chooser>
  <hbox>
    <button ok></button>
    <button cancel></button>
  </hbox>
</vbox>
</window>"

    I=$IFS; IFS=""
    for STATEMENT in  $(gtkdialog3 --program NETWIZ_Ndiswrapper_Chooser 2>/dev/null); do
      eval $STATEMENT
    done
    IFS=$I
    clean_up_gtkdialog NETWIZ_Ndiswrapper_Chooser
    unset NETWIZ_Ndiswrapper_Chooser

    echo "$EXIT"
	case $EXIT in 
	 Cancel|abort) return 1 ;;
	 OK) 
	   PREV_LOCATION=${INF_FILE_NAME%/*}
       echo "$PREV_LOCATION" > "$CONFIG_DIR/prev_location"
       # an extra protection, in case the dialog can't handle blank...
       [ "$PREV_LOCATION" ] || PREV_LOCATION="$HOME"
       case "$INF_FILE_NAME" in 
        *.[iI][nN][fF])
          return 0
          ;;
        *) # else
          giveErrorDialog "$L_MESSAGE_Bad_Inf_Name"
          ;;     
       esac
	   ;;
	esac
  done
}
#selectDriverFile()
#{
  #while true ; do
    #INF_FILE_NAME="$(Xdialog --left --title \"Select the driver information file \(.INF\)\" \
     #--stdout --no-buttons --fselect \"${PREV_LOCATION}/*\" 0 0)" 
    #if [ $? -eq 0 ] ; then
      ##PREV_LOCATION="`expr "$INF_FILE_NAME" : '\(.*\)/'`"
      #PREV_LOCATION=${INF_FILE_NAME%/*}
      #echo "$PREV_LOCATION" > "$CONFIG_DIR/prev_location"
      ##echo "$INF_FILE_NAME" | grep -Eiq "\.inf$" 
      ##if [ $? -eq 0 ] ; then
      #case "$INF_FILE_NAME" in 
       #*.[iI][nN][fF])
         #selectDriverFile_RC=0
         #break
         #;;
       #*) # else
         #Xdialog --screen-center --title "$L_TITLE_Netwiz_Ndiswrapper" \
            #--msgbox "The file name should end in \".inf\"" 0 0
         #;;     
      #esac #fi
    #else
      #selectDriverFile_RC=1
      #break
    #fi
  #done

  #return $selectDriverFile_RC
#} # end of selectDriverFile

#=============================================================================
showNdiswrapperGUI()
{
  CONFIG_DIR=/root/.config/ndiswrapperGUI

  [ -d "$CONFIG_DIR" ] || mkdir -p "$CONFIG_DIR"
  PREV_LOCATION=$(cat "$CONFIG_DIR/prev_location" 2>/dev/null)
  if [ ! "$PREV_LOCATION" ] || [ ! -d "$PREV_LOCATION" ] ; then
    INF_FILE_NAME=""
    PREV_LOCATION="$HOME"
  fi

  selectDriverFile
  if [ $? -eq 0 ] ; then
    expr "$INF_FILE_NAME" : '.*/\(.*\).inf' | tr "[A-Z]" "[a-z]"
    ndiswrapper -i "$INF_FILE_NAME" > /tmp/net-setup_NDISWRAPPER_LOAD.txt
    NDISWRAPPER_RESULT=$?
		case $NDISWRAPPER_RESULT in
			0 | 25 | 255) 
					Xdialog --left --screen-center --title "$L_TITLE_Netwiz_Ndiswrapper" \
              --msgbox "$(ndiswrapper -l)" 0 0
		      return 0
          ;;
			*) 	Xdialog --left --screen-center --title "L_TITLE_Netwiz_Ndiswrapper" \
              --msgbox "$(cat /tmp/net-setup_NDISWRAPPER_LOAD.txt)" 0 0
          ;;
		esac
  fi
  return 1
} # end of showNdiswrapperGUI


#=============================================================================
#=============== START OF SCRIPT BODY ====================
#=============================================================================

# If ran by itself it shows the interface, Otherwise it's only used as a function library
CURRENT_CONTEXT=$(expr "$0" : '.*/\(.*\)$' )
if [ "${CURRENT_CONTEXT}" = "ndiswrapperGUI.sh" ] ; then
	showNdiswrapperGUI
fi 

#=============================================================================
#=============== END OF SCRIPT BODY ====================
#=============================================================================
