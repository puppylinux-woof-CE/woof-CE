# Profile for Java JDK and JRE
JAVADIR="$(javaiffind)"

if [ "$JAVADIR" ];then
 export JAVA_HOME=$JAVADIR
 if [ -d "$JAVADIR/jre" ]; then #JDK
  export JRE_HOME=$JAVA_HOME/jre
  if [ -d /opt/android/android-studio/bin ];then
   export STUDIO_JDK=$JAVA_HOME
  fi
  export PATH=$(echo ${PATH} | sed 's%:[^:]*/j[dr][ke]-*[1-9/][^:]*%%g'):$JAVA_HOME/bin
 else
  export JRE_HOME=$JAVA_HOME
  export PATH=$(echo ${PATH} | sed 's%:[^:]*/j[dr][ke]-*[1-9/][^:]*%%g'):$JRE_HOME/bin;
 fi
 export LD_LIBRARY_PATH=$(echo ${LD_LIBRARY_PATH} | sed 's%:[^:]*/j[dr][ke]-*[1-9/][^:]*%%g'):$JRE_HOME/lib/i386:$JRE_HOME/lib/i386/client
fi
unset JAVADIR

# Deactivate possible jdk profile to avoid conflict.
if [ -s /etc/profile.d/jdk ];then
 mv -f /etc/profile.d/jdk /etc/profile.d/.jdk-superceded_by_profile_java.txt
 touch /etc/profile.d/jdk
 sync
fi

# Deactivate possible CLASSPATH and remove old 'java' profile, to avoid conflict.
if [ -f /etc/profile.d/java ];then
 rm -f /etc/profile.d/java
 [ "$CLASSPATH" ] && export CLASSPATH=''
fi
