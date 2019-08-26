For Puppy 4.1+
--------------

Firewall:

When the firewall is installed, it will be in /etc/rc.d
folder as "rc.firewall" and the file "rc.local" will
have an entry to start it.
"rc.local" is called from "rc.sysinit".

Startup:

When Puppy boots, the order of execution of the
scripts is (except for a full-hd installation):

  /init (in the initial ramdisk)

  switch_root occurs, some content of / relocates to /initrd
  and the following scripts then executed:

  /etc/rc.d/rc.sysinit
    Called from rc.sysinit:
    /etc/rc.d/rc.update
    /etc/rc.d/rc.network  (as a parallel process)
    /etc/rc.d/rc.services (as a parallel process)
    /etc/rc.d/rc.country
    /etc/rc.d/rc.local    (created by rc.sysinit if doesn't exist)
    
  /etc/profile

Puppy doesn't use runlevels.

Note, the only script listed above that is not user-editable is init,
as this is pristine out of initrd.gz.

Full-hd installation
--------------------
An exception to the above description is a full hard drive installation.
In that case, initrd.gz is not used, and there is no pivot_root and no
/initrd folder. This mode has PUPMODE=2.
The above sequence is still correct, except that the Busybox /sbin/init
is the first thing that executes, then rc.sysinit, etc.

Note1: /etc/rc.d/functions is from Slackware. Some service scripts in /etc/init.d/
      may use it.
