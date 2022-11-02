# Profile for Java JDK and JRE
# Supports 64/32-bit, openjdk, Oracle Javas.
#190904 Renamed to z-java.sh from java.sh, to override JAVA_HOME and paths possibly set by java package profiles; add support of openjdk & icedtea (javaws) deb packages.
#201121 Correct tests for java library path.

JAVADIR="$(javaiffind)" #Latest installed java and icedtea paths 
ICEDTEADIR="$(echo -n "$JAVADIR " | cut -f 2 -d ' ')"
JAVADIR="$(echo -n $JAVADIR | cut -f 1 -d ' ')"

if [ -n "$JAVADIR" ]; then
 export JAVA_HOME=$JAVADIR

 # Tell Android Studio.
 if [ -d /opt/android/android-studio/bin ];then
  export STUDIO_JDK=$JAVADIR
 fi

 # Add path(s) for executables.
 JAVAPATH=''; JREPATH=''; ICEDTEAPATH=''
 if [ -n "$(ls $JAVADIR/bin 2>/dev/null)" ]; then
  JAVAPATH=":$JAVADIR/bin"
  if [ -d $JAVADIR/jre/bin ] && [ ! -x "$JAVAPATH/java" ]; then
   JREPATH=":$JAVADIR/jre/bin"
  fi
  if [ -n "$ICEDTEADIR" ] && [ -x $ICEDTEADIR/bin/javaws ]; then
   ICEDTEAPATH=":$ICEDTEADIR/bin"
  fi
 fi
 export PATH="$(echo "${PATH}" | \
  sed -e 's%:[^:]*/j[dr][ke]-*[1-9/][^:]*%%g' \
  -e 's%:[^:]*/java/[^:]*%%g')${JAVAPATH}${JREPATH}${ICEDTEAPATH}"

 # Add library path to libjvm.
 if [ -f $JAVADIR/lib/server/libjvm.so ]; then #201121
  JAVALIBDIR="$JAVADIR/lib/server"
 elif [ -f $JAVADIR/jre/lib/*/server/libjvm.so ]; then #201121
  JAVALIBDIR="$(ls -d $JAVADIR/jre/lib/*/server)"
 elif [ -f $JAVADIR/lib/*/server/libjvm.so ]; then #201121
  JAVALIBDIR="$(ls -d $JAVADIR/lib/*/server)"
 fi
 if [ -n "$JAVALIBDIR" ]; then
  export LD_LIBRARY_PATH="$(echo "${LD_LIBRARY_PATH}" | sed 's%:[^:]*/j[dr][ke]-*[1-9/][^:]*%%g'):$JAVALIBDIR"
 fi

 # Override MANPATH if already set by open java.
 if [ -n "$MANPATH" ]; then
  NEWMANPATH="$(echo "${MANPATH}" | sed 's%[:^][^:]*/java[^:]*%%g')"
  if [ -f $JAVADIR/man/man1/java.1.gz ]; then
   NEWMANPATH="${NEWMANPATH}:$JAVADIR/man"
  fi
  if [ "$NEWMANPATH" != "$MANPATH" ]; then
   if [ -n "$NEWMANPATH" ]; then
    export MANPATH="$NEWMANPATH"
   else
    unset -v MANPATH
   fi
  fi
 fi
fi
unset -v JAVADIR ICEDTEADIR JAVAPATH JREPATH ICEDTEAPATH JAVALIBDIR NEWMANPATH
