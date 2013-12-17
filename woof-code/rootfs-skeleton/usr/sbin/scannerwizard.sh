#!/bin/sh
#Scanner Wizard (c) Barry Kauler 2003 www.goosee.com/puppy
#2007 Lesser GPL licence v2 (http://www.fsf.org/licensing/licenses/lgpl.html)

#SCRIPT NOT FINISHED

#this script creates /etc/scanner, which has format driver[:device].
#note, we could also have /dev/scanner linked to device.

#display window with driver info...
#dillo "file:///usr/share/doc/sane/sane-backends.htm" &
defaultbrowser "http://www.mostang.com/sane/sane-backends.html" &
sleep 1

STATUSabaton="off"
STATUSagfafocus="off"
STATUSapple="off"
STATUSartec="off"
STATUSartec_eplus48u="off"
STATUSas6e="off"
STATUSavision="off"
STATUSbh="off"
STATUScanon="off"
STATUScanon630u="off"
STATUScanon_pp="off"
STATUScoolscan="off"
STATUScoolscan2="off"
STATUSepson="off"
STATUSfujitsu="off"
STATUSgt68xx="off"
STATUShp="off"
STATUShpsj5s="off"
STATUSibm="off"
STATUSleo="off"
STATUSma1509="off"
STATUSmatsushita="off"
STATUSmicrotek="off"
STATUSmicrotek2="off"
STATUSmustek="off"
STATUSmustek_pp="off"
STATUSmustek_usb="off"
STATUSnec="off"
STATUSpie="off"
STATUSplustek="off"
STATUSricoh="off"
STATUSs9036="off"
STATUSsceptre="off"
STATUSsharp="off"
STATUSsm3600="off"
STATUSsnapscan="off"
STATUSsp15c="off"
STATUSst400="off"
STATUStamarack="off"
STATUSteco1="off"
STATUSteco2="off"
STATUSteco3="off"
STATUSumax="off"
STATUSumax1220u="off"
STATUSumax_pp="off"

if [ -e /etc/scanner ];then
 #/etc/scanner may have a format of drive:device...
 CURRENTSCANNER="`cat /etc/scanner | cut -f 1 -d ":"`"
# STATUS$CURRENTSCANNER="on"
case "$CURRENTSCANNER" in
 abaton ) STATUSabaton="on" ;;
 agfafocus ) STATUSagfafocus="on" ;;
 apple ) STATUSapple="on" ;;
 artec ) STATUSartec="on" ;;
 artec_eplus48u ) STATUSartec_eplus48u="on" ;;
 as6e ) STATUSas6e="on" ;;
 avision ) STATUSavision="on" ;;
 bh ) STATUSbh="on" ;;
 canon ) STATUScanon="on" ;;
 canon630u ) STATUScanon630u="on" ;;
 canon_pp ) STATUScanon_pp="on" ;;
 coolscan ) STATUScoolscan="on" ;;
 coolscan2 ) STATUScoolscan2="on" ;;
 epson ) STATUSepson="on" ;;
 fujitsu ) STATUSfujitsu="on" ;;
 gt68xx ) STATUSgt68xx="on" ;;
 hp ) STATUShp="on" ;;
 hpsj5s ) STATUShpsj5s="on" ;;
 ibm ) STATUSibm="on" ;;
 leo ) STATUSleo="on" ;;
 ma1509 ) STATUSma1509="on" ;;
 matsushita ) STATUSmatsushita="on" ;;
 microtek ) STATUSmicrotek="on" ;;
 microtek2 ) STATUSmicrotek2="on" ;;
 mustek ) STATUSmustek="on" ;;
 mustek_pp ) STATUSmustek_pp="on" ;;
 mustek_usb ) STATUSmustek_usb="on" ;;
 nec ) STATUSnec="on" ;;
 pie ) STATUSpie="on" ;;
 plustek ) STATUSplustek="on" ;;
 ricoh ) STATUSricoh="on" ;;
 s9036 ) STATUSs9036="on" ;;
 sceptre ) STATUSsceptre="on" ;;
 sharp ) STATUSsharp="on" ;;
 sm3600 ) STATUSsm3600="on" ;;
 snapscan ) STATUSsnapscan="on" ;;
 sp15c ) STATUSsp15c="on" ;;
 st400 ) STATUSst400="on" ;;
 tamarack ) STATUStamarack="on" ;;
 teco1 ) STATUSteco1="on" ;;
 teco2 ) STATUSteco2="on" ;;
 teco3 ) STATUSteco3="on" ;;
 umax ) STATUSumax="on" ;;
 umax1220u ) STATUSumax1220u="on" ;;
 umax_pp ) STATUSumax_pp="on" ;;
esac
fi

RESULTOK="`Xdialog --wmclass "scannerwizard" --title "Puppy scanner wizard" --stdout \
 --radiolist "Read doc window then choose scanner driver..." 28 65 4 \
 "abaton" "Abaton" $STATUSabaton \
 "agfafocus"   "Agfa, Siemens"   $STATUSagfafocus   \
 "apple"  "Apple" $STATUSapple  \
 "artec"   "Artec/Ultima, BlackWidow,Plustek"   $STATUSartec   \
 "artec_eplus48u"  "Artec/Ultima, Medion(etc),Trust,Memorex,Umax" $STATUSartec_eplus48u \
 "as6e" "Artec/Ultima" $STATUSas6e \
 "avision" "Avision, HP,Minolta,Mitsubishi,Fujitsu" $STATUSavision \
 "bh" "Bell and Howell" $STATUSbh \
 "canon" "Canon" $STATUScanon \
 "canon630u" "Canon" $STATUScanon630u \
 "canon_pp" "Canon" $STATUScanon_pp \
 "coolscan" "Nikon" $STATUScoolscan \
 "coolscan2" "Nikon" $STATUScoolscan2 \
 "epson" "Epson" $STATUSepson \
 "fujitsu" "Fujitsu" $STATUSfujitsu \
 "gt68xx" "Mustek, Plustek,Artec,Boeder,PkdBell,Medion,Trust,Lexmark,Genius" $STATUSgt68xx \
 "hp" "Hewlett Packard, Photosmart/scanner" $STATUShp \
 "hpsj5s" "Hewlett Packard" $STATUShpsj5s \
 "ibm" "IBM, Ricoh" $STATUSibm \
 "leo" "LEO, Across Technologies, Genius" $STATUSleo \
 "ma1509" "Mustek" $STATUSma1509 \
 "matsushita" "Panasonic" $STATUSmatsushita \
 "microtek" "Microtek, Agfa" $STATUSmicrotek \
 "microtek2" "Microtek, Vobis,Scanport" $STATUSmicrotek2 \
 "mustek" "Mustek, Trust,Primax" $STATUSmustek \
 "mustek_pp" "Mustek, Medion(etc),Targa,Trust,Viviscan,Cybercom,Gallery" $STATUSmustek_pp \
 "mustek_usb" "Mustek, Trust" $STATUSmustek_usb \
 "nec" "NEC" $STATUSnec \
 "pie" "PIE, Devcom,Adlib" $STATUSpie \
 "plustek" "Plustek, Primax,Genius,Aries,B-Scan,Mustek,HP,Epson,Umax,Compaq,Canon" $STATUSplustek \
 "ricoh" "Ricoh" $STATUSricoh \
 "s9036" "Siemens" $STATUSs9036 \
 "sceptre" "Sceptre, Komodo" $STATUSsceptre \
 "sharp" "Sharp" $STATUSsharp \
 "sm3600" "Microtek" $STATUSsm3600 \
 "snapscan" "Agfa, Benq,Guillemot,Mitsubishi,Epson" $STATUSsnapscan \
 "sp15c" "Fijitsu" $STATUSsp15c \
 "st400" "Siemens" $STATUSst400 \
 "tamarack" "Tamarack" $STATUStamarack \
 "teco1" "Relisys, Actown,Dextra" $STATUSteco1 \
 "teco2" "Relisys, Primax" $STATUSteco2 \
 "teco3" "Relisys, Plustek,Piotech,Trust" $STATUSteco3 \
 "umax" "Umax, Linotype Hell,Vobis,Edge,Epson,Escom,Escort,Genius,Nikon" $STATUSumax \
 "umax1220u" "Umax" $STATUSumax1220u \
 "umax_pp" "Umax" $STATUSumax_pp  2> /dev/null`"

STATUSRET=$?

if [ $STATUSRET -eq 0 ];then
 echo -n "$RESULTOK" > /etc/scanner
 Xdialog --wmclass "scannerwizard" --title "Puppy scanner wizard" \
 --infobox "SCRIPT NOT FINISHED. DOESN'T ACTUALLY DO ANYTHING!" \
 8 50 10000 2> /dev/null
fi
