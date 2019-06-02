#!/bin/sh
#called from /usr/local/petget/downloadpkgs.sh
#/tmp/petget_proc/petget_repos has the list of repos, each line in this format:
#z|http://repository.slacky.eu/slackware-12.2|Packages-slackware-12.2-slacky
#...only the first field is of interest in this script.


echo '#!/bin/sh' >  /tmp/petget_proc/petget_urltest
echo 'echo "Testing the URLs:"' >>  /tmp/petget_proc/petget_urltest
echo '[ "$(cat /var/local/petget/nt_category 2>/dev/null)" != "true" ] && [ -f /tmp/petget_proc/install_quietly ] && set -x' >>  /tmp/petget_proc/petget_urltest

for ONEURLSPEC in `cat /tmp/petget_proc/petget_repos`
do
 #ex: distro.ibiblio.org
 URL_TEST="`echo -n "$ONEURLSPEC" | cut -f 2 -d '|' | cut -f 3 -d '/'`" 
 echo 'echo' >> /tmp/petget_proc/petget_urltest
 echo "wget -t 2 -T 20 --waitretry=20 --spider -S $URL_TEST" >> /tmp/petget_proc/petget_urltest
done

echo 'echo "
TESTING FINISHED
Read the above, any that returned \"200 OK\" succeeded."' >>  /tmp/petget_proc/petget_urltest
echo 'echo -n "Press ENTER key to exit: "
read ENDIT'  >>  /tmp/petget_proc/petget_urltest

chmod 777 /tmp/petget_proc/petget_urltest
if [ ! -f /tmp/petget_proc/install_quietly ]; then
 rxvt -title "Puppy Package Manager: download" -bg orange \
 -fg black -e /tmp/petget_proc/petget_urltest
else
 exec /tmp/petget_proc/petget_urltest
fi

###END###
