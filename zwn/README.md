Currently this will build a very basic Slackware Puppy, which boots to console.

There are no wizards to setup the internet connection.

If you have a working WIRED ETHERNET, run:
- dhcpcd

Wait a few seconds and test if there is a working connection:
- ping 8.8.8.8 (ctrl-c to stop it)

Now you're ready to test slapt-get:
- slapt-get --update

Install packages, etc, it should work.
- slapt-get --install lynx

More info
- slapt-get --help


How to build:
-----
1. Put this in a largish directory *OUTSIDE* your
   save file (e.g. in some external partition like /mnt/sda3 that uses
   Unix partition - ext2/3/4 btrfs xfs f2fs etc will be good).
   
2. Run ./setup.sh. Answer a few questions, and you will get a "workdir".

3. cd workdir

4. ./build-sfs.sh --- this will build the puppy.sfs (basesfs) in 
   iso/iso-root.

5. ./build-iso.sh --- this will make an ISO, the iso is located in
   iso/puppy.iso
   
6. If you have qemu, you can then ./runqemu.sh to boot that puppy.iso.

7. Ready for more? Run "./setup.sh work2" from the top directory, and 
   choose another build parameters. 
   "cd work2", and re-do step 4-6 above to create another puppy build.
   You can keep multiple builds in its own separate directory this way.
   
   Or you can modify the "basesfs" package list. This file contains
   the selection of the packages that get built. Add/remove packages
   to tailor to your own needs.
   
   Build your own kernel with kernel-kit (see the README inside).
   Enable Fatdog-style kernel build, and put the resulting vmlinuz and 
   kernel-modules.sfs to iso/iso-root of your work directory.
   
   Build your own devx by running "./build-sfs.sh devx" from the
   work directory. If you need NLS, then "nls-holder" contains the
   locale files removed from the basesfs build, simply "mksquashfs" 
   them.
   
   The possibilities are endless!

Have fun.

/James

NOTE: If you're trying to build 64-bit system, please make sure that 
your own OS is 64-bit. You can't build 64-bit on 32-bit system.
On the other hand, 64-bit system will happily build 32-bit puppies.

