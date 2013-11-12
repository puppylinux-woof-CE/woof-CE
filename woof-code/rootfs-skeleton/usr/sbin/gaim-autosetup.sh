#!/bin/sh
#
# gaim-autosetup.sh -- generates autologin configuration for GAIM 
#                      so that starting GAIM will log user into #puppylinux
#
# Copyright 2006 Jonathan Marsden
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 ,
# as published by the Free Software Foundation.
#           
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#                           
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# bugfix bk 2006

IRCHOST='irc.freenode.net'
IRCCHANNEL='#puppylinux'
IRCPORT=6667
PREFIX='PupUser-'
GAIMCONFIGDIR=~/.gaim
PROMPT="Enter the IRC Nickname you wish to use"
XDIALOGOPTIONS="--stdout --no-cancel --title $0"

# Exit if either of the two files we are generating already exists
if test -f $GAIMCONFIGDIR/accounts.xml
then
  exit 1
fi

if test -f $GAIMCONFIGDIR/blist.xml
then
  exit 2
fi

# Generate a semi-random IRC username
USERNAME=$PREFIX`(date ;cat /proc/cpuinfo)|md5sum|sed -e's/^\(......\).*$/\1/'`

# Prompt for Nick if -v option used
if test "$1" = "-v"
then
  NEWNAME=`Xdialog $XDIALOGOPTIONS --inputbox "$PROMPT" 0 0 "$USERNAME"`
  if test "$?" -eq 0
  then
    USERNAME=`echo $NEWNAME |tr -cd 'A-Za-z0-9[-\`{-}'` # See RFC 2812 2.3.1
  fi  
fi

# Create the two config files
cat >$GAIMCONFIGDIR/accounts.xml <<EOF
<?xml version='1.0' encoding='UTF-8' ?>

<accounts version='1.0'>
 <account>
  <protocol>prpl-irc</protocol>
  <name>$USERNAME@$IRCHOST</name>
  <settings>
   <setting name='username' type='string'>$USERNAME</setting>
   <setting name='encoding' type='string'>UTF-8</setting>
   <setting name='realname' type='string'>$USERNAME</setting>
   <setting name='port' type='int'>$IRCPORT</setting>
  </settings>
  <settings ui='gtk-gaim'>
   <setting name='auto-login' type='bool'>1</setting>
  </settings>
 </account>
</accounts>
EOF

cat >$GAIMCONFIGDIR/blist.xml <<EOF
<?xml version='1.0' encoding='UTF-8' ?>

<gaim version='1.0'>
        <blist>
                <group name="Buddies">
                        <setting name="collapsed" type="bool">0</setting>
                        <chat proto="prpl-irc" account="$USERNAME@$IRCHOST">
                                <component name="channel">$IRCCHANNEL</component>
                                <component name="password"></component>
                                <setting name="gtk-autojoin" type="bool">1</setting>
                        </chat>
                </group>
        </blist>
        <privacy>
                <account proto="prpl-irc" name="$USERNAME@$IRCHOST" mode="1">
                </account>
        </privacy>
</gaim>
EOF
