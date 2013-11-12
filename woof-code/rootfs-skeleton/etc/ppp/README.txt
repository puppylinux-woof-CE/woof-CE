BK 17jun03:

When you run "ppp -s" in a terminal, the ppp connection
will get setup, and the files "pap-secrets" and "chap-secrets"
will get generated in this folder (these have the password).
The files "options" and "chat-script" will get updated.

When you make a connection to the ISP, by typing "ppp -c"
the file "resolv.conf" will get automatically updated with 
the DNSs (assuming IP addresses are dynamically assigned by 
the ISP) -- otherwise you will have to edit this file
-- read the docs /usr/share/doc/pppsetup.htm

BK 26jun03:

I've installed /usr/sbin/xnetload*, a GUI app to display 
packet traffic while connected to the Internet.

BK 25sept03:

I've installed Gkdial, a GUI dialer. I had to hack the source
code a bit to get it to work.
It allows multiple accounts, puts the chatscripts into
/etc/ppp/chatscripts/ and account info into /etc/ppp/peers/.

So, the earlier ppp* console app should still work, no
conflict, except that "ppp -s" creates "ip-up" script, which
is executed by pppd* after successful connection, so this
will also occur when using Gkdial.
...should be ok, ip-up puts up a little message using xmessage,
about the successful connection ...in the case of Gkdial this
is redundant ...so maybe I'll edit the default ip-up provided
inside image.gz.

BK 22Nov2004:

Roaring Penguin pppoe has a problem with /etc/ppp/resolv.conf (which is
just a link to /etc/resolv.conf). Gkdial writes to the former, not the latter,
when an Internet dialup connection is made, so it has to stay.
So, if you want to use Roaring Penguin, rename /etc/ppp/resolv.conf to something
else to hide it (then though, you won't be able to use gkdial!).

/etc/ppp/options has been edited and the line /dev/modem has been commented
out with a "#". Roaring Penguin complains about the /dev/modem as "unrecognised
option".

6JULY2006:

wvdial warns that /etc/ppp/options may conflict with its own settings.
wvdial also uses /etc/ppp/peers/wvdial and wvdial-pipe, that conflicts with
Gkdial.
So, create a script, /usr/sbin/gnomepppshell, to move those files away,
then back afterward.

The desktop 'connect' icon is now a Rox applet, at /usr/local/apps/Connect/.

