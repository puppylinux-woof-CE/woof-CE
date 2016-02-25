
0bPress <F2> key to go to basic help07
If you need particular boot options, type0d BOOTLABEL07 then a space,
then each boot option. Some boot options:

0bThese help locating files at bootup. Examples:07
0dpdev1=sdc107      The boot partition.
0dpsubdir=puppies/wary50107 Path in which Puppy is installed.
0dpsavemark=207     Partition no. (in boot drive) to save session to.
0dpmedia=usbflash07 Type of media booting from. Choose one of these:
             usbflash usbhd usbcd ataflash atahd atacd atazip scsihd scsicd cd
0dpupsfs=sdc1:/puppies/wary501/puppy.sfs07 Override auto search.
0dzdrv=sdc1:/puppies/wary501/zdrv.sfs07    Override auto search.
0dunderdog=sda907   Mount an entire Linux distro (in sda9) underneath Puppy.
0dpmedia=cd pfix=ram07 Ignore saved session and do not look in other drives
0bThe following are for debugging, for experts only:07
0dloglevel=<n>07    Bootup verbosity. 7 is high verbosity for debugging.
0dpfix=rdsh07       Execute 'init' then dropout to prompt in initramfs.
0dpfix=rdsh007      Dropout early, before loading kernel drivers.
0dpfix=rdsh607      Dropout just before mount layered filesystem.
0dpimod=a.ko,b.ko07 'insmod' these kernel module files.

More help here: http://kernel.org/doc/Documentation/kernel-parameters.txt

