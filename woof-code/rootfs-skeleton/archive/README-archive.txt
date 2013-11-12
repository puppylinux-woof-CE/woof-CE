For the multisession CD/DVD, any files in /archive/
will get saved to CD/DVD at end of session, but they will
not "come back".

That is, they will not be back in /archive/ at the next session.
But they are still on the CD/DVD.

This is a handy way to conserve space in the ramdisk.

The same goes for this file!

MULTISESSION CD/DVD NOTE:
At shutdown, the shutdown script, /etc/rc.d/rc.shutdown, moves
some files to /archive automatically, to try and save space in the
ramdisk. These are tar and compressed files, for example all
.tar.gz files. Also any files over 99M in size.
