BK 15may03:

/etc/resolv.conf
This has your ISP's domain name servers (DNSs).
Normally, these will be supplied automatically by
the ISP and this file will be written to during
the connection ...look at the script /etc/ppp/ip-up*

 3Nov04: See note in /etc/ppp/README.txt.
         I have removed all default entries from /etc/resolv.conf,
         so it is now just an empty file -- suggestion is that
         Roaring Penguin pppoe needs this.

/etc/nsswitch.conf
A PPP HOWTO recommended this file be there, with the line:
hosts: files dns
in it. Note, the file in Red Hat has heaps more stuff.

/etc/host.conf
The PPP HOWTO states that this must have the line:
order hosts,bind

/etc/hosts
This file has the lines:
127.0.0.1 localhost.localdomain localhost
0.0.0.0 puppypc
where second line is name of the computer. I read somewhere
that you could have:
0.0.0.0 localhost
on the second line, instead of name of the computer.

/etc/hostname
This also has the name of the computer:
puppypc
That's all, just one word in the file.
Note that /etc/rc.d/rc.sysinit reads this file and executes
"hostname" application, thus setting the system to this name.

/etc/rc.d/rc.sysinit
Stuff in here gets executed during startup.
It calls rc.modules, which loads kernel driver modules.

/etc/profile
After Bash/Ash (command prompt) is running, this file is executed.
It's just like "autoexec.bat" in MSDOS.

NOTE:
To troubleshoot your PPP dialup connection, refer to
/usr/share/doc/pppsetup.htm
also look in /etc/modules.conf and /etc/rc.d/rc.modules
