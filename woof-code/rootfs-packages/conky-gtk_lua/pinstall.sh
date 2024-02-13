#!/bin/sh

/usr/bin/conky-gtk --enable-autostart # generate autostart script at ~/Startup/conkystart

cp /root/.config/conky-gtk/conkyrc /root/.config/conky-gtk/conkyrc.bak # generate backup file

ln -s /root/.config/conky-gtk/conkyrc /root/.conkyrc # make conkyrc symlink at ~/
