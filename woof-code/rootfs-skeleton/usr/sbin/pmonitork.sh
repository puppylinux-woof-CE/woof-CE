#!/bin/sh
# log a file tail

#Xdialog --title "Monitoring tail of $1" --smooth --fixed-font --no-cancel --ok-label "Exit" --tailbox $1 18 95

LINES1=0
LINES2=0
while [ 1 ];do
 LINES2=`wc -l /var/log/messages | tr -s " " | cut -f 2 -d " "`
 if [ $LINES2 -gt $LINES1 ];then
  LINESDIFF=`expr $LINES2 - $LINES1`
  tail -n $LINESDIFF /var/log/messages
  LINES1=$LINES2
 fi 
 sleep 1
done
