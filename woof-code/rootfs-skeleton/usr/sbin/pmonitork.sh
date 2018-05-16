#!/bin/sh
# log a file tail

#Xdialog --title "Monitoring tail of $1" --smooth --fixed-font --no-cancel --ok-label "Exit" --tailbox $1 18 95

tail -f /var/log/messages
