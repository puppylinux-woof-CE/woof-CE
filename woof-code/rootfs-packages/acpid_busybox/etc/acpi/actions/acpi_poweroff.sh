#!/bin/sh
# Patriot Jan 2009 for Puppy Linux 4.1.1 GPL
# Revision 0.0.6
# 13sep09 dialogbox by shinobar
# 4nov09 TIMELIMIT 30sec
# 26dec09 wmpoweroff, adjustable less than 10sec.
# 12feb10 stop acpid before powroff
# 29nov11 01micko: suspend button
# 6dec11 rhadon : fix did not shut off
# 12apr12 shinobar: avoid duplicated POPUP of pupsaveconfig
# 23apr12 shinobar: checkbox to suspend at timeout
#20140526 shinobar: the first run creating pupsave (PUPMODE=5), avoid multiple run
#20140621 shinobar: skip shutdownconfig when power button pressed before quicksetup done, avoid multiple run
 
TIMELIMIT=30	# sec, no dialog if 0(zero).
TIMELIMIT_S=10	# default timelimit for suspend on timeout
#TIMELIMIT_P=30	# timeout for the first run, creating pupsave
CHATTER=4	# seconds, aoid multiple invoked

#20140621: avoid multiple run
LOCKFILE=/tmp/acpi_poweroff-flg
if [ -f "$LOCKFILE" ]; then
  PID=$(cat "$LOCKFILE")
  ps| grep "^[ ]*$PID " && exit
  # last script can be just finshed
  LAST=$(stat -c '%Y' "$LOCKFILE")
  [ "$LAST" ] || LAST=0
  NOW=$(date +'%s')
  [ $(($NOW - $LAST)) -lt $CHATTER ] && exit
fi
echo -n "$$" > "$LOCKFILE"
sleep 1
[ "$(cat "$LOCKFILE")" = "$$" ] || exit 0 

SUSPEND_PROG=/etc/acpi/actions/suspend.sh
[ -x "$SUSPEND_PROG" ] || SUSPEND_PROG=""
ACPI_CONFIG=/etc/acpi/acpi.conf
TIME_LIMIT=""
TIMEOUT_ACTION='poweroff'
[ -s "$ACPI_CONFIG" ] && . "$ACPI_CONFIG"
case "$DISABLE_SUSPEND" in
y*|Y*|true|True|TRUE|1) SUSPEND_PROG="";;
esac
SUSPEND_AT_TIMEOUT='false'
if [ "$TIMEOUT_ACTION" = 'suspend' ]; then
  SUSPEND_AT_TIMEOUT='true'
  TIMELIMIT=$TIMELIMIT_S
fi
[ "$TIME_LIMIT" ] && TIME_LIMIT=$(echo $TIME_LIMIT| tr -dc '0-9')
[ "$TIME_LIMIT" ] && TIMELIMIT=$TIME_LIMIT
SUSPEND_AT_TIMEOUT_ORG=$SUSPEND_AT_TIMEOUT
[ "$TIMELIMIT" ] || TIMELIMIT=0	#precaution

#dummy mode
case "$1" in
ram|RAM) PUPMODE=5; DEBUG_MODE="y";;
*debug) DEBUG_MODE="y";;
esac

SOUND="/usr/share/audio/bark.au"
PLAY="aplay"
[ -f "$SOUND" ] && which $(basename $PLAY) >/dev/null && $(basename $PLAY) "$SOUND"

if [ -n "$DISPLAY" -o -n "$WAYLAND_DISPLAY" ]; then

 for P in gtkdialog3 gtkdialog gtkdialog4; do
   which $P &>/dev/null && GTKDIALOG=$P
 done
 if [ -z "$GTKDIALOG" ]; then
   echo "gtkdialog NOT found."
   TIMELIMIT=0
 fi
 if [ $TIMELIMIT -gt 0 ]; then
  export TEXTDOMAIN=acpi_poweroff
  export TEXTDOMAINDIR=/usr/share/locale
  export OUTPUT_CHARSET=UTF-8

  _farewell=$(gettext "Power button is pushed, and about to shut down...")
  _check_suspend=$(gettext "Suspend at timeout")
  _Shuting_down=$(gettext "Shutting down in %s seconds.")
  _Suspend_in=$(gettext "Suspend in %s seconds.")
  _Click_OK=$(gettext "Click 'OK' to shutdown right now, or 'Cancel' to continue Puppy.")
  _Click_Suspend=$(gettext "Click 'OK' to shutdown right now, 'Suspend' to suspend Puppy, or 'Cancel' to continue Puppy.")
  _Susupend=$(gettext "Suspend")
  _Cancel=$(gettext "Cancel")
  _OK=$(gettext "OK")
  _CANCELTIP=$(gettext "Cancel shutdown, and continue Puppy.")
  _OKTIP=$(gettext "Shutdown right now.")
  _SUSPENDTIP=$(gettext "Suspend right now.")

   # NLS in old text style
   mo=acpi.mo
   # set locale
   for lng in C $(echo $LANGUAGE|cut -d':' -f1) $LC_ALL $LANG;do :;done   # ex.    ja_JP.UTF-8
   # search locale file
   lng1=$(echo $lng|cut -d'.' -f1)      # ex.   ja_JP
   lng2=$(echo $lng|cut -d'_' -f1)   # ex.   ja
   LOCALEDIR=/usr/share/locale
   [ "$mo" ] || mo=$(basename $0).mo
   for D in en C $lng2 $lng1 $lng
   do
     F="$LOCALEDIR/$D/LC_MESSAGES/$mo"
     [ -f "$F" ] && file "$F" | grep -qw 'text' && . "$F"
   done

  CANCEL_BUTTON='<button tooltip-text="'$_CANCELTIP'"><input file stock="gtk-cancel"></input><label>"'$_Cancel'"</label><action type="exit">Cancel</action></button>'
  OK_BUTTON='<button tooltip-text="'$_OKTIP'"><input file stock="gtk-ok"></input><label>"'$_OK'"</label><action type="exit">OK</action></button>'
   MSG="$_farewell"
   MSG1=$_Shuting_down
   _limit0=$_limit1
   if [ "$SUSPEND_PROG" ]; then
    if [ "$SUSPEND_AT_TIMEOUT" = 'true' ]; then
      MSG1=$_Suspend_in
      _limit0=$_limitS
    fi
    MSG2="$_Click_Suspend"
    BUTTONS='<hbox>
   '$CANCEL_BUTTON'
   <button tooltip-text="'$_SUSPENDTIP'">
    <input file stock="gtk-media-pause"></input>
    <label>"'$_Susupend'"</label>
    <action type="exit">suspend</action>
   </button>
   '$OK_BUTTON'
  </hbox>
  <checkbox><label>"'$_check_suspend'"</label><variable>SUSPEND_AT_TIMEOUT</variable><default>$SUSPEND_AT_TIMEOUT</default></checkbox>'
   else
    MSG2="$_Click_OK"
     BUTTONS='<hbox>
    '$CANCEL_BUTTON'
    '$OK_BUTTON'
    </hbox>'
   fi
  [ "$MSG1" ] && MSG1=$(printf "$MSG1" $TIMELIMIT)
 
   DIV=10
   [ $TIMELIMIT -le 20 ] && DIV=5
   [ $TIMELIMIT -le 10 ] && DIV=$TIMELIMIT
   STEP=$(($TIMELIMIT / $DIV))
   TIMELIMIT=$(($STEP * $DIV))
   PITCH=$((100 / $DIV))

   export DIALOG='<window title="acpid"><vbox>
  <text><label>"'$MSG'"</label></text>
  <progressbar><label>"'$MSG1'"</label>
      <input>for i in $(seq 0 '$PITCH' 100); do echo $i; sleep '$STEP'; done; echo 100</input>
      <action type="exit">timeout</action>
  </progressbar>
  <text><label>"'$MSG2'"</label></text>
  '$BUTTONS'
 </vbox></window>'
 #echo "$DIALOG"
	eval $($GTKDIALOG -p DIALOG -c || echo "$DIALOG" >&2)
	touch "$LOCKFILE"	# refresh finish time
	if [ "$SUSPEND_AT_TIMEOUT" != "$SUSPEND_AT_TIMEOUT_ORG" ]; then
	  TIMEOUT_ACTION='poweroff'
	  [ "$SUSPEND_AT_TIMEOUT" = 'true' ] && TIMEOUT_ACTION='suspend'
	  echo "TIME_LIMIT=$TIME_LIMIT # sec, no dialog if 0(zero).
TIMEOUT_ACTION='$TIMEOUT_ACTION'	# 'poweroff'/'suspend'" > $ACPI_CONFIG
	fi
	case "$EXIT" in
	  Cancel|abort) exit 0;;
	  No) touch "$PUPSAVEFLAG"	#skip pupsaveconfig/shutdownconfig
	    ;;
	esac
	if [ "$EXIT" = "suspend" ] || [ "$EXIT" = "timeout" -a "$TIMEOUT_ACTION" = 'suspend' ]; then
	  touch /tmp/suspend && [ "$SUSPEND_PROG" ] && exec "$SUSPEND_PROG"  # 6dec11 rhadon, 20140526 shinobar
    fi
 fi
 P=wmpoweroff
else
 #20140621 shinobar: skip shutdownconfig when power button pressed before quicksetup done
 touch /tmp/shutdownconfig_results	# skip shutdownconfig
 if [ ! -s /etc/rc.d/pupsave.conf ]; then # compatible with pupsaveconfig
   echo 'PRECHOICE=no
POPUP=no' > /etc/rc.d/pupsave.conf
 fi
 P=poweroff
fi
#rm -f "$LOCKFILE"
[ "$DEBUG_MODE" ] && exit

touch /tmp/powerbutton.flg	#no effect for now, but reserved for future use
[ -x /etc/init.d/rc.acpi ] && /etc/init.d/rc.acpi stop || killall acpid
exec $P
