System services
---------------

"daemon"
...this word is used below. It means an application that when executed, runs continually in the background.

The scripts in /etc/init.d are executed at bootup and shutdown to start and stop services.

At bootup, the /etc/rc.d/rc.services script will run all executable scripts found in /etc/init.d, with the commandline parameter 'start'.
At shutdown, the /etc/rc.d/rc.shutdown script will run all executable scripts found in /etc/init.d, with the commandline parameter 'stop'.

Puppies built from the Woof build system after January 26, 2010, have System Service Management provided in the BootManager (see Sysytem menu). This Services Manager controls which of these scripts will run by setting or clearing their 'executable' flag -- a script flagged as executable will run, otherwise not.

System Services Management
--------------------------

Most users do not normally need to disable any of the system services, however sometimes there might be a need. 

Each service uses CPU and memory resources, so with a slow CPU there may be some noticeable gain in not running services that are not needed.

On rare occasions a service may cause trouble, so needs to be disabled.

Here are some notes on particular services:

cups
----
This runs the CUPS daemon 'dbusd', required for printing. Leave this enabled unless you don't need to print.

messagebus
----------
Runs the daemon 'dbusd'.
DBUS is a method for applications to communicate with one another. Only certain applications use this, and most puppies are built with apps that don't. If 'messagebus' script is present, it probably means some application is installed that needs DBUS. An example is 'gecko-mediaplayer' (browser plugin) that uses DBUS to communicate with 'gnome-mplayer' (multimedia player). So, unless you know that no apps require this, leave it enabled.

rc.acpi
-------
Runs the daemon 'acpid'.
This is a daemon that provides certain ACPI management functions. Puppy will still work without it.

rc.firewall
-----------
In most puppies this scipt is actually located at /etc/rc.d. If you have Internet access then this is essential to provide protection. It doesn't actually launch any daemon, only loads kernel modules, so runtime resource usage is low. The only time that you might want to disable it is when testing the Internet connection.

slmodem
-------
Runs the daemon 'slmodemd'.
This provides support for some analog dialup modems. There are reports that this can conflict with sound on some PCs, so if you don't use an analog modem for Internet access, or a different modem driver, consider disabling this.

start_cpu_freq
--------------
This is not a daemon, it just loads kernel modules for "ondemand" CPU frequency scaling and activates it. This is desirable for modern netbooks and laptops, as it reduces power consumption and CPU temperature. If you disable this, then the CPU will run continuously at its maximum frequency, which is probably fine for desktop PCs.
Note that at the time of writing, the 'start_cpu_freq' script exits immediately without activating ondemand if the PC BIOS is older than 2006 -- this is because many older CPUs don't work well with ondemand frequency scaling.

sys_logger
----------
This runs the daemons 'syslogd' and 'klogd', which log kernel and application events (espcially error messages) to various log files, mostly to /var/log/messages. This can be disabled and Puppy will still work.

udev
----
Runs the daemons 'udevd' and 'pup_event_frontend_d'.
This is a mechanism that receives information about hardware events from the kernel, such as a USB pen drive being plugged in or removed. If you don't want automatic detection of hardware changes while Puppy is running, Puppy will still work and you will save quite a lot of CPU usage and resources -- worth considering this one on a very slow CPU.

This one is different from those listed above, as 'udevd' is essential during bootup. However, it can be killed after bootup -- it involves the daemon 'udevd' and the daemon 'pup_event_frontend_d' and if disabled these two are killed when X is started. The technical description is that when X starts, /root/.xinitrc runs, which launches /sbin/pup_event_frontend_d -- look in that latter script and you will see that it reads /etc/eventmanager which has a variable 'BACKENDON' that can be set to kill udevd and pup_event_frontend_d.

There is a GUI manager for this, the EventManager (see System menu), and changing the 'udev' checkbox will cause the EventManager to run.


Technical notes
---------------

At startup, the system services are executed by /etc/rc.d/rc.services, which in turn is called from /etc/rc.d/rc.sysinit.

At shutdown, the system servcies are executed (with the 'stop' parameter) by /etc/rc.d/rc.shutdown.

Puppy does not have runlevels (basically because Busybox doesn't, at least that was the original reason). Normal Linux distros would have a list of services to start for each runlevel, but apart from not having runlevels Puppy also only runs a very minimum essential set of services, that most users would not want to tamper with.

Note that /etc/rc.d/init.d is a symlink to /etc/init.d

Note, the scripts in /etc/init.d can have any name, but must have their executable flag set. Any file that does not have the 'x' flag set will be ignored.

Regards,
Barry Kauler
Jan. 2010
