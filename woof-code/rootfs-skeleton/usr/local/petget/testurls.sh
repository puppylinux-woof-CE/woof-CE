#!/bin/sh
#called from /usr/local/petget/downloadpkgs.sh
#/tmp/petget_repos has the list of repos, each line in this format:
#repository.slacky.eu|http://repository.slacky.eu/slackware-12.2|Packages-slackware-12.2-slacky
#...only the first field is of interest in this script.

echo '#!/bin/sh' >  /tmp/petget_urltest
echo 'echo "Testing the URLs:"' >>  /tmp/petget_urltest

for ONEURLSPEC in `cat /tmp/petget_repos`
do
 URL_TEST="`echo -n "$ONEURLSPEC" | cut -f 1 -d '|'`"
 
 #[ "`wget -t 2 -T 20 --waitretry=20 --spider -S $ONE_PET_SITE -o /dev/stdout 2>/dev/null | grep '200 OK'`" != "" ]
 
 echo 'echo' >> /tmp/petget_urltest
 echo "wget -t 2 -T 20 --waitretry=20 --spider -S $URL_TEST" >> /tmp/petget_urltest
 
done

echo 'echo "
TESTING FINISHED
Read the above, any that returned \"200 OK\" succeeded."' >>  /tmp/petget_urltest
echo 'echo -n "Press ENTER key to exit: "
read ENDIT'  >>  /tmp/petget_urltest

chmod 777 /tmp/petget_urltest
rxvt -title "Puppy Package Manager: download" -bg orange -fg black -e /tmp/petget_urltest

###END###
