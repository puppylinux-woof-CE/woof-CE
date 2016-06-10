The key to understanding how Puppy works is the initial boot script,
/initrd/init.

In a nutshell, everything you see in /initrd is the "initial ramdisk",
which is actually /dev/ram0. For Puppy 4.0 and later, the kernel uses a slightly
different technique and it is more correct to call it the "initramfs" and
/dev/ram0 is not used.

With Puppy prior to 4.0, the initial ramdisk is not discarded after bootup.
From 4.0 onward, the initramfs is discarded, but much of it is transfered to
the main filesystem in the /initrd directory. Technically different, but
similar end result from the users point of view.

The directories pup_rw, pup_ro1, etc are mounted on "/" when Puppy is running.
The number of them mounted is variable, at least pup_rw will be.
The usual situation is pup_rw, pup_ro1 and pup_ro2 are mounted on "/".
When control transfers from the initial ramdisk or initramfs to the main filesystem,
these mount-points are relocated to inside /initrd.

/initrd/pup_rw
This is the writable folder. Usually it is tmpfs (temporary filesystem) in ram.
However, a personal storage file (named "pup_save.2fs" or similar) or partition 
could be mounted directly on here (in which case it won't be on /initrd/pup_ro1).

/initrd/pup_ro1
This is usually your saved files, and the contents of pup_rw get saved to here,
periodically or at end of session. In other words, your personal storage file or
partition is mounted here, except see above note.
Note that this is mounted rw, although unionfs makes it behave as ro on "/".

/initrd/pup_ro2
These are all the Puppy files. Normally we don't write to this, we keep it pristine.
This file is named something like "pup-430.sfs" or similar, where the "410" is the
3-digit version number.

/initrd/pup_ro3
Recent versions of Puppy built with the Woof build system, in 2009 or later, may
have a "zdrv" mounted on here. This is a situation in which the kernel modules and
firmware are in a separate file named "zp430nnn.sfs" or similar (the essential
feature to recognise this file is it starts with letter "z" and has the version
number in it).

unionfs
Mounts the directories in this order:
 pup_rw
 pup_ro1
 pup_ro2
 pup_ro3
 pup_ro4
 pup_ro5
 etc.

Where the higher directory has precedence. For example if files of the same name
exist in pup_rw and pup_ro1, the file in pup_rw is the one that is "seen".

------------------
Barry Kauler 2009.
