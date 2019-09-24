#!/bin/ash
# /etc/init.d/javaif.sh
# Derived from /etc/init.d/java.sfs.sh in java-sfs.sh by Uten

[ "$1" ] || exit
ARGUMENT="$1"

update_icedtea_configuration () {
    if [ -n "$ICEDTEAHOME" ]; then
     ICEDTEAVERSION="$(grep -osm 1 '"icedtea-web .*"' \
      $ICEDTEAHOME/man/man1/icedtea-web.1 \
      $ICEDTEAHOME/share/man/man1/icedtea-web.1 | \
      sed 's/.*"icedtea-web (*\([0-9.]*\).*/\1/')"
     for ONEEXEC in itweb-settings javaws policyeditor; do
      if [ -x /usr/bin/$ONEEXEC ]; then
       if [ -h /usr/bin/$ONEEXEC ]; then
        rm -f /usr/bin/$ONEEXEC
       else
        chmod a-x /usr/bin/$ONEEXEC
       fi
      fi
     done
    else
     ICEDTEAVERSION=''
     for ONEEXEC in itweb-settings javaws policyeditor; do
      if [ -f /usr/bin/$ONEEXEC ]; then
       chmod a+x /usr/bin/$ONEEXEC
      elif [ -f $JAVAHOME/bin/$ONEEXEC ]; then
        ln -snf $JAVAHOME/bin/$ONEEXEC /usr/bin/$ONEEXEC
      fi
     done
    fi
}

#Main:
case "$ARGUMENT" in
 start|change)
  [ "$ARGUMENT" = 'start' ] && sleep 1 #Wait for other java service scripts before overriding them, then do change
  JAVAHOME=''; JAVAVERSION=''; ICEDTEAHOME=''; ICEDTEAVERSION=''
  if [ -f /root/.javaifrc ]; then
   . /root/.javaifrc #dynamic info
  fi
  PREVJAVAHOME="$JAVAHOME"; PREVVERSION="$JAVAVERSION"
  PREVICEDTEAHOME="$ICEDTEAHOME"; PREVICEDTEAVERSION="$ICEDTEAVERSION"

  JAVAHOME="$(javaiffind)" #Latest installed java version & icedtea-web
  ICEDTEAHOME="$(echo -n "$JAVAHOME " | cut -f 2 -d ' ')"
  JAVAHOME="$(echo -n $JAVAHOME | cut -f 1 -d ' ')"
  if [ "$JAVAHOME" ]; then
   JAVAVERSION="$($JAVAHOME/bin/java -version 2>&1 | grep 'version' | cut -f3 -d ' ' | tr -d '\"')"

   update_icedtea_configuration

   JAVAIFRC="JAVAHOME=$JAVAHOME
JAVAVERSION=$JAVAVERSION
ICEDTEAHOME=$ICEDTEAHOME
ICEDTEAVERSION=$ICEDTEAVERSION"
   if [ ! -f /root/.javaifrc ] || [ "$JAVAIFRC" != "$(cat /root/.javaifrc)" ]; then
    echo -n "$JAVAIFRC" > /root/.javaifrc
   fi
  else
   rm -f /root/.javaifrc
  fi
  ;;
esac

