echo "Resolve devx perl differences Ubuntu - Debian"

cd ./sandbox3/devx
mv -v usr/lib/i386-linux-gnu/perl5/5.32/auto/* usr/lib/i386-linux-gnu/perl5/5.34/auto/
mv -v usr/lib/i386-linux-gnu/perl5/5.32/Compress usr/lib/i386-linux-gnu/perl5/5.34/
mv -v usr/lib/i386-linux-gnu/perl5/5.32/Digest usr/lib/i386-linux-gnu/perl5/5.34/

mv -f usr/share/perl5/ExtUtils/* usr/share/perl/5.32.1/ExtUtils/
mv -f usr/share/perl5/Locale/* usr/share/perl/5.32.1/Locale/
mv -f usr/share/perl5/Parse/* usr/share/perl/5.32.1/Parse/
mv -f usr/share/perl5/Text/* usr/share/perl/5.32.1/Text/
mv -ufv usr/share/perl5/* usr/share/perl/5.32.1/

mv -v usr/share/perl/5.32.1 usr/share/perl/5.34.0
ln -s 5.34.0 usr/share/perl/5.34

cd ../../
