#!/bin/sh
#BK may 2011

PWD="`pwd`"
SETDEFAULT='no'

if [ "$PWD" = "/" ];then #installing in a running puppy.

 if [ "`cat /root/.packages/woof-installed-packages /root/.packages/user-installed-packages | grep 'gecko\-mediaplayer'`" = "" ];then
  EXTRAMSG="<text>
      <label>Note: It is highly recommended that you also install Gecko-mediaplayer, a web browser plugin. These two applications are designed to work together.</label>
    </text>"
 fi
 
 export ASKDIALOG="
<window title=\"Ask\" decorated=\"false\" window_position=\"1\" skip_taskbar_hint=\"true\">
  <vbox>
  <frame>
    <text>
      <label>Hi, you have just installed Gnome-mplayer. Click the 'Yes' button if you would like Gnome-mplayer to become the default media player, otherwise click 'No'. Note, you can also manually edit /usr/local/bin/defaultmediaplayer and /usr/local/bin/defaultvideoplayer at any time to change the default.</label>
    </text>
    ${EXTRAMSG}
    <hbox>
     <button> <label>Yes</label>  <action type=\"exit\">SetDefault</action> </button>
     <button> <label>No</label>  <action type=\"exit\">NotDefault</action> </button>
    </hbox>
  </frame>
  </vbox>
</window>
"
 RETVAL="`gtkdialog3 --program=ASKDIALOG`"
 echo "$RETVAL"
 [ "`echo "$RETVAL" | grep 'SetDefault'`" != "" ] && SETDEFAULT='yes'
fi

if [ "$PWD" != "/" -o "$SETDEFAULT" = "yes" ];then

  echo '#!/bin/sh' > ./usr/local/bin/defaultmediaplayer
  echo 'exec gnomemplayershell "$@"' >> ./usr/local/bin/defaultmediaplayer
  chmod 755 ./usr/local/bin/defaultmediaplayer

  echo '#!/bin/sh' > ./usr/local/bin/defaultvideoplayer
  echo 'exec gnomemplayershell "$@"' >> ./usr/local/bin/defaultvideoplayer
  chmod 755 ./usr/local/bin/defaultvideoplayer

fi
