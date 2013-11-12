Any executable or scripts (or symlink to) placed in this directory
will be executed after the X desktop has loaded.

This is handy if you want something to run automatically.

You can easily create a "symlink" (symbolic link) to an executable.
For example, say that you wanted to run /usr/local/bin/rubix (a game)
everytime Puppy is started. Use ROX-Filer (the file manager) and open
two windows, one on /usr/local/bin, the other on /root/Startup.
Then just drag 'rubix' across and a menu will popup and ask if you want
to copy, move or link, and you choose to link.

Note, if you want to execute something at bootup and prior to X desktop
loading, edit /etc/rc.d/rc.local.
