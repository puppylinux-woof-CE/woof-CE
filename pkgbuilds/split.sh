#!/bin/bash
# directly pilfered from new2dir
#support build number

[ "$1" ] && tgt="${1}"

TIMEOUT='-t 1'
ARCH=`uname -m`
if [ ! "$CPUTYPE" ];then
  if [ -f config.log ];then
  BuildCPU=`grep -m1 '^build_cpu='.*'' config.log |cut -f 2 -d "'"`
  HostCPU=`grep -m1 '^host_cpu='.*'' config.log |cut -f 2 -d "'"`
    if [ "$HostCPU" != "$BuildCPU" ];then
    echo "WARNING build_cpu='$BuildCPU' NOT host_cpu='$HostCPU'"
    fi
  CPUTYPE="$BuildCPU"
  fi
  if [ ! "$CPUTYPE" ];then
    if [ ! "$TIMEOUT" ];then
    CPUTYPE="i486"
    else
    CPUTYPE="$ARCH"
    fi
  else
  echo "Found '$CPUTYPE'"
  fi
fi

[ -z "$2" ] || CPUTYPE=${CPUTYPE}_${2}
CURRDIR="`pwd`"
PKGDIR="../`basename "$CURRDIR"`"
xPKGDIR="`basename "$CURRDIR"`"
EXE_TARGETDIR="${PKGDIR}-${CPUTYPE}" #relative path.
EXE_PKGNAME="`basename $EXE_TARGETDIR`"
RELPATH="`dirname $EXE_TARGETDIR`"
#difficult task, separate package name from version part... 
#not perfect, some start with non-numeric version info...
xNAMEONLY="`echo -n "$xPKGDIR" | sed -e 's/\-[0-9].*$//g'`"
#...if that fails, do it the old way...
[ "$xNAMEONLY" = "$xPKGDIR" ] && xNAMEONLY="`echo "$xPKGDIR" | cut -f 1 -d "-"`"
NAMEONLY="${RELPATH}/${xNAMEONLY}"
#abasename="`basename ${PKGDIR}`"
apattern="s/${xNAMEONLY}\\-//g"
VERONLY="`echo -n "$xPKGDIR" | sed -e "$apattern"`"
DOC_TARGETDIR="${NAMEONLY}_DOC-${VERONLY}-${CPUTYPE}"
DEV_TARGETDIR="${NAMEONLY}_DEV-${VERONLY}-${CPUTYPE}"
NLS_TARGETDIR="${NAMEONLY}_NLS-${VERONLY}-${CPUTYPE}"

NLSSPLIT=yes
DOCSPLIT=yes
DEVSPLIT=yes
EXESPLIT=yes

mkdir -p "$EXE_TARGETDIR" 2>/dev/null

while read ONEFILE
do
 ONEFILE="../${ONEFILE}"
 ONEBASE=${ONEFILE##*/} #"`basename "$ONEFILE"`"
 ONEPATH=${ONEFILE%/*}  #"`dirname "$ONEFILE"`"
 echo "Processing ${ONEFILE}"
 #echo $ONEPATH
 NEWPATH=${ONEPATH//$tgt/}  #NEWPATH="`echo $ONEPATH|sed "s%$tgt%%"`"
 #echo $NEWPATH
 [ "$ONEFILE" = "$tgt" ] && continue
 #strip the file...
 if [ ! -h "$ONEFILE" ];then #make sure it isn't a symlink
   FILE_INFO=$(file "$ONEFILE")
   case $FILE_INFO in *"ELF"*)
     case $FILE_INFO in
       *"shared object"*) strip --strip-debug "$ONEFILE" ;;
       *"executable"*) strip --strip-unneeded "$ONEFILE" ;;
     esac
   esac
 fi
 sync

 if [ "$NLSSPLIT" = "yes" ];then
  #find out if this is an international language file...
  case "$ONEFILE" in *"/locale/"*|*"/nls/"*|*"/i18n/"*)
   mkdir -p "${NLS_TARGETDIR}/${NEWPATH}" 2>/dev/null
   cp -af "$ONEFILE" "${NLS_TARGETDIR}/${NEWPATH}/" 2>/dev/null
   continue
  esac
 fi

 if [ "$DOCSPLIT" = "yes" ];then
  #find out if this is a documentation file...
  case "$ONEFILE" in *"/man/"*|*"/doc/"*|*"/doc-base/"*|*"/docs/"*|*"/info/"*|*"/gtk-doc/"*|*"/faq/"*|*"/manual/"*|*"/examples/"*|*"/help/"*|*"/htdocs/"*)
   mkdir -p "${DOC_TARGETDIR}/${NEWPATH}" 2>/dev/null
   cp -af "$ONEFILE" "${DOC_TARGETDIR}/${NEWPATH}/" 2>/dev/null
   continue
  esac
 fi

 if [ "$DEVSPLIT" = "yes" ];then
  #find out if this is development file...
  case "$ONEFILE" in *"X11/config/"*|*"/include/"*|*"/pkgconfig/"*|*"/aclocal"*|*"/cvs/"*|*"/svn/"*|*"/src/"*)
   mkdir -p "${DEV_TARGETDIR}/${NEWPATH}" 2>/dev/null
   cp -af "$ONEFILE" "${DEV_TARGETDIR}/${NEWPATH}/" 2>/dev/null
   continue
  esac
  
  #all .a and .la files... and any stray .m4 files...
  case "$ONEFILE" in *.a|*.la|*.m4)
    mkdir -p "${DEV_TARGETDIR}/${NEWPATH}" 2>/dev/null
    cp -af "$ONEFILE" "${DEV_TARGETDIR}/${NEWPATH}/" 2>/dev/null
    continue
  esac
 fi

 #anything left over goes into the main 'executable' package...
 if [ "$EXESPLIT" = "yes" ];then
  mkdir -p "${EXE_TARGETDIR}/${NEWPATH}" 2>/dev/null
  cp -af "$ONEFILE" "${EXE_TARGETDIR}/${NEWPATH}/" 2>/dev/null
 fi
done < ${RELPATH}/${EXE_PKGNAME}.files

#130121 grab a .pot if it exists...
sync
pnPTN="/${xNAMEONLY}.pot"
if [ "`grep "$pnPTN" ${RELPATH}/${EXE_PKGNAME}.files`" = "" ];then
 FNDPOT="$(find ${CURRDIR}/ -type f -name "${xNAMEONLY}.pot" | head -n 1)"
 if [ "$FNDPOT" ];then
  mkdir -p ${EXE_TARGETDIR}/usr/share/doc/nls/${xNAMEONLY} 2>/dev/null
  cp -f "$FNDPOT" ${EXE_TARGETDIR}/usr/share/doc/nls/${xNAMEONLY}/
  echo "${tgt#*/}/usr/share/doc/nls/${xNAMEONLY}/" >> ${RELPATH}/${EXE_PKGNAME}.files
  echo "${tgt#*/}/usr/share/doc/nls/${xNAMEONLY}/${xNAMEONLY}.pot" >> ${RELPATH}/${EXE_PKGNAME}.files
 fi
fi

sync

echo "all done"
exit

###END###
