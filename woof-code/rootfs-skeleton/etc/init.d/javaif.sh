#!/bin/ash
# /etc/init.d/javaif.sh
# Derived from /etc/init.d/java.sfs.sh in java-sfs.sh by Uten

[ "$1" ] || exit
ARGUMENT="$1"

get_nonhomed_icedtea_version () {
    # Get version when icedtea-netx is not in a home directory.
    DEFAULTICEDTEAVERSION='1.7.2'
    ICEDTEAVERSION="$(/usr/share/icedtea-web/bin/javaws.sh --version -headless 2>/dev/null | \
     grep -m 1 -E '^icedtea-web|^null' | cut -f 2 -d ' ' | sed "s/null/$DEFAULTICEDTEAVERSION/")"
    if [ -z $ICEDTEAVERSION ] \
      && [ -f /usr/share/icedtea-web/man/man1/icedtea-web.1.gz ]; then
     ICEDTEAVERSION="$(gunzip --stdout /usr/share/icedtea-web/man/man1/icedtea-web.1.gz | \
       grep -osm 1 '"icedtea-web .*"' | \
       sed -n 's/.*"icedtea-web (*\([0-9.]*\))*.*/\1/p')"
    fi
}
    
set_up_for_newest_icedtea_version () {
    if [ -x $ICEDTEAHOME/bin/javaws ]; then
     ICEDTEAVERSION="$($ICEDTEAHOME/bin/javaws --version -headless 2>/dev/null | \
      grep -m 1 -E '^openjdk|icedtea-web' | cut -f 2 -d ' ')"
     if [ -z $ICEDTEAVERSION ]; then
      ICEDTEAHOMEVERSION="$(grep -osm 1 '"icedtea-web .*"' \
       $ICEDTEAHOME/man/man1/icedtea-web.1 \
       $ICEDTEAHOME/share/man/man1/icedtea-web.1 | \
       sed -n 's/.*"icedtea-web (*\([0-9.]*\).*/\1/p')"
     fi
     if [ -z $ICEDTEAVERSION ] || vercmp $ICEDTEAHOMEVERSION gt $ICEDTEAVERSION; then
      ICEDTEAVERSION=$ICEDTEAHOMEVERSION
     fi
     for ONEEXEC in itweb-settings javaws policyeditor; do
      if [ -f /usr/bin/$ONEEXEC ]; then
       if  [ -x /usr/share/icedtea-web/bin/${ONEEXEC}.sh ];then
        chmod a-x /usr/bin/$ONEEXEC
       else
        rm -f /usr/bin/$ONEEXEC
       fi
      fi
     done
    fi
}
     
set_up_for_nonhomed_icedtea_version () {
    for ONEEXEC in itweb-settings javaws policyeditor; do
     if [ -f /usr/bin/$ONEEXEC ]; then
      if [ -f /usr/share/icedtea-web/bin/${ONEEXEC}.sh ];then
       chmod a+x /usr/bin/$ONEEXEC
      else
       rm -f /usr/bin/$ONEEXEC
      fi
     elif [ -f /usr/share/icedtea-web/bin/${ONEEXEC}.sh ]; then
       ln -snf /usr/share/icedtea-web/bin/${ONEEXEC}.sh /usr/bin/$ONEEXEC
     fi
    done
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
  JAVAVERSION="$($JAVAHOME/bin/java --version 2>/dev/null)" \
   || JAVAVERSION="$($JAVAHOME/bin/java -version 2>&1)"
  JAVAVERSION="$(echo $JAVAVERSION | grep -m 1 '^openjdk' | \
   sed -e 's/ version//' -e 's/"//g' -e 's/ 1\./ /' | cut -f 2 -d ' ')"

   get_nonhomed_icedtea_version # e. g., debian
   if [ -n "$ICEDTEAHOME" ]; then
    # Use newest of non-homed and home-directoried implementations.
    set_up_for_newest_icedtea_version
   else
    # Use non-homed implementation if present.
    set_up_for_nonhomed_icedtea_version
   fi

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

