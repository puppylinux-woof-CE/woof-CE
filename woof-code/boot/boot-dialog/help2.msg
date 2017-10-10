
0bPress <F2> key to go to basic help07
If you need particular boot options, type0d BOOTLABEL07 then a space,
then each boot option. Some boot options:
0bThese help locating files at bootup. Examples:07
0dpdev1=sdc107      The boot partition.
0dpsubdir=/pups/DISTRO_FILE_PREFIX07 Path in which Puppy is installed.
0dpsavemark=207     Partition no. (in boot drive) to save session to.
0dpmedia=usbflash07 Type of media booting from. Choose one of these:
             usbflash usbhd usbcd ataflash atahd atacd atazip scsihd scsicd cd
0bThe following parameters specify various system files, overiding defaults:07
0dpupsfs07 Main puppy sfs      0dzdrv07 zdrv sfs    0dfdrv07 fdrv sfs
0dpsave07  Save session file   0dadrv07 adrv sfs    0dydrv07 ydrv sfs
They all have the same format 0dparamater=partition:filename07
0dpartition07 can be a name "sdc1", a Label "Work" or UUID "49baa82d-8c69"
0dfilename07 can be "/path/filename", "filename" or absent (":" not needed)
Examples:
0dadrv=Work:/other/myadrv.sfs07 adrv in "/other" on partition labeled "Work"
0dydrv=sdc1:myydrv.sfs07        ydrv in 0dpsubdir07 on partition named "sdc1"
0dpsave=49baa82d-8c6907         Save session on partition with UUID "49baa82d-8c69"
0bThe following are for debugging, for experts only:07
0dpfix=rdsh07       Execute 'init' then dropout to prompt in initramfs.
0dpimod=a.ko,b.ko07 'insmod' these kernel module files.
More help here: http://kernel.org/doc/Documentation/kernel-parameters.txt
