#!/bin/sh
#called from pkg_chooser.sh, findnames.sh, filterpkgs.sh
#post-process the selection of pkgs that is to be displayed, according to the exe, dev, doc, nls checkboxes.
#120515 script created, common code extracted from above 3 scripts.
#120525 fix post-filtering.
#120529 prefix an icon to each line of results.
#120719 support raspbian.
#120811 category field now supports sub-category |category;subcategory|, use as icon in ppm main window.
#120813 fix subcategory icon.
#120817 modify 'category' field: Document;edit becomes mini-Document-edit (will use icon mini-Document-edit.xpm)

#ui_Ziggy and ui_Classic pass in two params, ex: EXE true
[ $2 ] && echo -n "$2" > /var/local/petget/postfilter_${1}

#101129 postprocess, show EXE, DEV, DOC, NLS...
DEF_CHK_EXE='true'
DEF_CHK_DEV='false'
DEF_CHK_DOC='false'
DEF_CHK_NLS='false'
[ -e /var/local/petget/postfilter_EXE ] && read DEF_CHK_EXE < /var/local/petget/postfilter_EXE
[ -e /var/local/petget/postfilter_DEV ] && read DEF_CHK_DEV < /var/local/petget/postfilter_DEV
[ -e /var/local/petget/postfilter_DOC ] && read DEF_CHK_DOC < /var/local/petget/postfilter_DOC
[ -e /var/local/petget/postfilter_NLS ] && read DEF_CHK_NLS < /var/local/petget/postfilter_NLS
cp -f /tmp/petget_proc/petget/filterpkgs.results /tmp/petget_proc/petget/filterpkgs.results.post

#120525 quick filtering but not perfect...
#PETs: _DEV _DOC _NLS  
#Ubuntu,Debian DEBs: -dev_ -doc_ -docs_ -langpack -lang-
#Mageia RPMs: -devel- -doc-
sed -i -e '/-dbg_/d' /tmp/petget_proc/petget/filterpkgs.results.post #120525 always take out the debug pkgs.
[ "$DEF_CHK_DEV" = "false" ] && sed -i -e '/_DEV/d' -e '/-dev_/d' -e '/-devel-/d' /tmp/petget_proc/petget/filterpkgs.results.post
[ "$DEF_CHK_DOC" = "false" ] && sed -i -e '/_DOC/d' -e '/-doc_/d' -e '/-docs_/d' -e '/-doc-/d' /tmp/petget_proc/petget/filterpkgs.results.post
[ "$DEF_CHK_NLS" = "false" ] && sed -i -e '/_NLS/d' -e '/-langpack/d' -e '/-lang-/d' /tmp/petget_proc/petget/filterpkgs.results.post
#120504b fix filtering out _EXE... 120515 must escape the dashes...
if [ "$DEF_CHK_EXE" = "false" ];then
 grep -E '_DEV|_DOC|_NLS|\-dev_|\-doc_|\-docs_|\-langpack|\-lang\-|\-devel\-|\-doc\-' /tmp/petget_proc/petget/filterpkgs.results.post > /tmp/petget_proc/petget/filterpkgs.results.post.tmp
 mv -f /tmp/petget_proc/petget/filterpkgs.results.post.tmp /tmp/petget_proc/petget/filterpkgs.results.post
fi

sed -i 's%;%-%' /tmp/petget_proc/petget/filterpkgs.results.post #make names correspond to /usr/share/icons/hicolor/scalable/categogies/

###END###
