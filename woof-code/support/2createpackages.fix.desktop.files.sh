#!/bin/sh
#
# fix *.desktop files..
#
# old code - slightly updated..
#

#set -x

ROOTDIR="$1"    # sandbox2
ONEDBENTRY="$2" # entry created by findpkgs

if [ -d ${ROOTDIR}/usr/share/applications ] ; then
	FND_DESKTOP="`find ${ROOTDIR}/usr/share/applications ${ROOTDIR}/usr/local/share/applications -type f -name \*.desktop 2>/dev/null | tr '\n' ' '`"
fi

if [ -z "$FND_DESKTOP" ] ; then
	exit # nothing to fix
fi

# https://specifications.freedesktop.org/desktop-entry-spec/latest/ar01s07.html
sed -i 's| %u||g ; s| %U||g ; s| %f||g ; s| %F||g' $FND_DESKTOP

#------------------------------------------------------------------------------
  
#db has category[;subcategory] (see 0setup), xdg enhanced (see /etc/xdg and /usr/share/desktop-directories), and generic icons for all subcategories.
DB_ENTRY="`echo -n "$ONEDBENTRY" | cut -f 4-19 -d '|'`" #take GENERICNAME|PETorCOMPAT|DBFILE| off start.
  
#find out if Categories entry in .desktop is valid, if not use 'category' field in pkg db...
CATEGORY="`echo -n "$DB_ENTRY" | cut -f 5 -d '|'`" #exs: Document, Document;edit
[ "$CATEGORY" = "" ] && CATEGORY='BuildingBlock' #paranoid precaution.
#xCATEGORY and DEFICON will be the fallbacks if Categories entry in .desktop is invalid...
xCATEGORY="`echo -n "$CATEGORY" | sed -e 's%^%X-%' -e 's%;%-%'`" #ex: X-Document-edit (refer /etc/xdg/menu/*.menu)
DEFICON="`echo -n "$CATEGORY" | sed -e 's%^%mini-%' -e 's%;%-%'`" #ex: mini-Document-edit (refer /usr/local/lib/X11/mini-icons -- these are in jwm search path)
case $CATEGORY in
	Calculate)     CATEGORY='Business'             ; xCATEGORY='X-Business'            ; DEFICON='Business.svg'            ;; #Calculate is old name, now Business.
	Develop)       CATEGORY='Utility;development'  ; xCATEGORY='X-Utility-development' ; DEFICON='Utility-development.svg' ;; #maybe an old pkg has this.
	Help)          CATEGORY='Utility;help'         ; xCATEGORY='X-Utility-help'        ; DEFICON='Help.svg'                ;; #maybe an old pkg has this.
	BuildingBlock) CATEGORY='Utility'              ; xCATEGORY='Utility'               ; DEFICON='BuildingBlock.svg'       ;; #unlikely to have a .desktop file.
esac
#check validity of Categories= and Icon= entries in .desktop file...
topCATEGORY="`echo -n "$CATEGORY" | cut -f 1 -d ';'`"
tPATTERN="^${topCATEGORY} "
cPATTERN="s%^Categories=.*%Categories=${xCATEGORY}%"
iPATTERN="s%^Icon=.*%Icon=${DEFICON}%"

#121120 if only one .desktop file, first check if a match in /usr/local/petget/categories.dat (see also /usr/local/petget/installpkg.sh)...
CATDONE='no'
if [ -f /usr/local/petget/categories.dat ];then #precaution, but it will be there -- yes, have added code above makes sure it is.
	NUMDESKFILE="$(echo -n "$FND_DESKTOP" | wc -w)"
	if [ "$NUMDESKFILE" = "1" ];then
		#to lookup categories.dat, we need to know the generic name of the package, which may be different from pkg name...
		#db entry format: pkgname|nameonly|version|pkgrelease|category|size|path|fullfilename|dependencies|description|compileddistro|compiledrelease|repo|
		DBNAMEONLY="$(echo -n "$DB_ENTRY" | cut -f 2 -d '|')"
		DBPATH="$(echo -n "$DB_ENTRY" | cut -f 7 -d '|')"
		DBCOMPILEDDISTRO="$(echo -n "$DB_ENTRY" | cut -f 11 -d '|')"
		case $DBCOMPILEDDISTRO in
			debian|devuan|ubuntu|raspbian) xNAMEONLY=${DBPATH##*/} ;;
			*) xNAMEONLY="$DBNAMEONLY" ;;
		esac
		xnPTN=" ${xNAMEONLY} "
		#130219 categories.dat format changed slightly... ignore case...
		CATVARIABLE="$(grep -i "$xnPTN" /usr/local/petget/categories.dat | grep '^PKGCAT' | head -n 1 | cut -f 1 -d '=' | cut -f 2,3 -d '_' | tr '_' '-')" #ex: PKGCAT_Graphic_camera=" gphoto2 gtkam "
		if [ "$CATVARIABLE" ];then #ex: Graphic-camera
			xCATEGORY="X-${CATVARIABLE}"
			cPATTERN="s%^Categories=.*%Categories=${xCATEGORY}%"
			CATFOUND="yes"
			CATDONE='yes'
		fi
	fi
fi
  
for ONEDESKTOP in $FND_DESKTOP
do
	CATFOUND="no"
	if [ "$CATDONE" = "no" ];then #121120
		for ONEORIGCAT in `cat $ONEDESKTOP | grep '^Categories=' | head -n 1 | cut -f 2 -d '=' | tr ';' ' ' | rev` #search in reverse order.
		do
			#find out if category already valid, if not fallback to xCATEGORY...
			ONEORIGCAT="`echo -n "$ONEORIGCAT" | rev`" #restore rev of one word.
			oocPATTERN=' '"$ONEORIGCAT"' '
			[ "`echo "$PUPHIERARCHY" | tr -s ' ' | grep "$tPATTERN" | cut -f 3 -d ' ' | tr ',' ' ' | sed -e 's%^% %' -e 's%$% %' | grep "$oocPATTERN"`" != "" ] && CATFOUND="yes"
			#got a problem with sylpheed, "Categories=GTK;Network;Email;News;" this displays in both Network and Internet menus...
			if [ "$CATFOUND" = "yes" ];then
				cPATTERN="s%^Categories=.*%Categories=${ONEORIGCAT}%"
				break
			fi
		done
		#121119 above may fail, as DB_category field may not match that in .desktop file, so leave out that $tPATTERN match in $PUPHIERARCHY...
		if [ "$CATFOUND" = "no" ];then
			for ONEORIGCAT in `cat $ONEDESKTOP | grep '^Categories=' | head -n 1 | cut -f 2 -d '=' | tr ';' ' ' | rev` #search in reverse order.
			do
				#find out if category already valid, if not fallback to xCATEGORY...
				ONEORIGCAT="`echo -n "$ONEORIGCAT" | rev`" #restore rev of one word.
				oocPATTERN=' '"$ONEORIGCAT"' '
				[ "`echo "$PUPHIERARCHY" | tr -s ' ' | cut -f 3 -d ' ' | tr ',' ' ' | sed -e 's%^% %' -e 's%$% %' | grep "$oocPATTERN"`" != "" ] && CATFOUND="yes"
				#got a problem with sylpheed, "Categories=GTK;Network;Email;News;" this displays in both Network and Internet menus...
				if [ "$CATFOUND" = "yes" ];then
					cPATTERN="s%^Categories=.*%Categories=${ONEORIGCAT}%"
					break
				fi
			done
		fi
	fi
   
	sed -i -e "$cPATTERN" $ONEDESKTOP #fix Category field.
	#does the icon exist?... fix .desktop... 110821 improve...
	ICON="`grep '^Icon=' $ONEDESKTOP | cut -f 2 -d '='`"
	if [ "$ICON" != "" ];then
		[ -e "${ROOTDIR}${ICON}" ] && continue #it may have a hardcoded path.
		[ -e "${ICON}" ] && continue #it may have a hardcoded path, look in running puppy.
		ICONBASE="${ICON##*/}" #basename "$ICON"
		#first search where jwm looks for icons...
		FNDICON=""
		if [ -d ${ROOTDIR}/usr/share/pixmaps ] ; then
			FNDICON="`find ${ROOTDIR}/usr/share/pixmaps -maxdepth 1 -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
		fi
		if [ "$FNDICON" ];then
			ICONNAMEONLY="${FNDICON##*/}" #basename $FNDICON
			iPTN="s%^Icon=.*%Icon=${ICONNAMEONLY}%"
			sed -i -e "$iPTN" $ONEDESKTOP
			continue
		else
			#look elsewhere, including in running puppy... DANGER DANGER
			FNDICON="`find ${ROOTDIR} /usr/share/icons /usr/share/pixmaps -name $ICONBASE -o -name $ICONBASE.png -o -name $ICONBASE.xpm -o -name $ICONBASE.jpg -o -name $ICONBASE.jpeg -o -name $ICONBASE.gif -o -name $ICONBASE.svg  | grep -i -E 'png$|xpm$|jpg$|jpeg$|gif$|svg$' | head -n 1`"
			if [ -n "${ROOTDIR}" ] ; then
				FNDICON="$(echo "$FNDICON" | sed -e "s%${ROOTDIR}%%")"
			fi
			if [ "$FNDICON" ];then
				ICONNAMEONLY="${FNDICON##*/}" #basename "$FNDICON"
				mkdir -p ${ROOTDIR}/usr/share/pixmaps #120514
				ln -snf "$FNDICON" ${ROOTDIR}/usr/share/pixmaps/${ICONNAMEONLY} #111207 fix path.
				sed -i -e "s%^Icon=.*%Icon=${ICONNAMEONLY}%" $ONEDESKTOP
				continue
			fi
		fi
		#substitute a default icon...
		sed -i -e "$iPATTERN" $ONEDESKTOP
	fi
done

### END ###