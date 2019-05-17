# needs $1 = dir

libs='lib/libcap.a
usr/lib/abiword-*/plugins/*.a
usr/lib/enchant/*.a
usr/lib/heimdal/*.a
usr/lib/libav*.a
usr/lib/liba52.a
usr/lib/libabiword-*.a
usr/lib/libart*.a
usr/lib/libattr.a
usr/lib/libaudio.a
usr/lib/libaudiofile.a
usr/lib/libaudit.a
usr/lib/libavfs.a
usr/lib/libbluray.a
usr/lib/libbonobo*.a
usr/lib/libbsd.a
usr/lib/libcaca.a
usr/lib/libcairo*.a
usr/lib/libcares.a
usr/lib/libcdda_paranoia.a
usr/lib/libcrmf.a
usr/lib/libcroco*.a
usr/lib/libdaemon.a
usr/lib/libdb-4.4.a
usr/lib/libdb_cxx-4.4.a
usr/lib/libdc1394.a
usr/lib/libdca.a
usr/lib/libdirect.a
usr/lib/libebml.a
usr/lib/libedit.a
usr/lib/libenca.a
usr/lib/libenchant.a
usr/lib/libevent*.a
usr/lib/libexif-gtk.a
usr/lib/libexiv2.a
usr/lib/libexslt.a
usr/lib/libfdisk.a
usr/lib/libfftw*.a
usr/lib/libfontconfig.a
usr/lib/libformw.a
usr/lib/libfreetype.a
usr/lib/libgc.a
usr/lib/libgconf-2.a
usr/lib/libgdbm.a
usr/lib/libgdk-x11-2.0.a
usr/lib/libGeoIP.a
usr/lib/libgio-2.0.a
usr/lib/libGLEW.a
usr/lib/libglib-2.0.a
usr/lib/libGLU.a
usr/lib/libglut.a
usr/lib/libgmlib.a
usr/lib/libgmtk.a
usr/lib/libgnet-2.0.a
usr/lib/libgnome*.a
usr/lib/libgnomeprint/*/modules/filters/*.a
usr/lib/libgnomeprint/*/modules/*.a
usr/lib/libgnomeprint/*/modules/transports/*.a
usr/lib/libgobject-2.0.a
usr/lib/libgphoto2/*/*.a
usr/lib/libgphoto2*.a
usr/lib/libgphoto2_port/*/*.a
usr/lib/libgsf-1.a
usr/lib/libgsf-gnome-1.a
usr/lib/libgtkhtml-2.a
usr/lib/libgtksourceview-2.0.a
usr/lib/libgtk-x11-2.0.a
usr/lib/libharfbuzz.a
usr/lib/libhistory.a
usr/lib/libhunspell-*.a
usr/lib/libical*.a
usr/lib/libICE.a
usr/lib/libicu*.a
usr/lib/libid3.a
usr/lib/libIDL-2.a
usr/lib/libidn2.a
usr/lib/libieee1284.a
usr/lib/libImlib2.a
usr/lib/libjackserver.a
usr/lib/libjbig2dec.a
usr/lib/libjim.a
usr/lib/libjpeg.a
usr/lib/libloudmouth-1.a
usr/lib/liblzo2.a
usr/lib/libmng.a
usr/lib/libnl-nf-3.a
usr/lib/libnl-route-3.a
usr/lib/libnsl.a
usr/lib/libnspr4.a
usr/lib/libofx.a
usr/lib/libogg.a
usr/lib/libopencore*.a
usr/lib/libopts.a
usr/lib/libORBit-2.a
usr/lib/liborc-0.4.a
usr/lib/libosp.a
usr/lib/libpango-1.0.a
usr/lib/libpcap.a
usr/lib/libperl.a
usr/lib/libpixman-1.a
usr/lib/libpng12.a
usr/lib/libpng14.a
usr/lib/libpoppler*.a
usr/lib/libqpdf.a
usr/lib/libraptor2.a
usr/lib/libreadline.a
usr/lib/librtmp.a
usr/lib/libsamplerate.a
usr/lib/libsasl2.a
usr/lib/libsepol.a
usr/lib/libsndfile.a
usr/lib/libsoup-2.4.a
usr/lib/libspeex.a
usr/lib/libsqlite3.a
usr/lib/libssl.a
usr/lib/libsw*.a
usr/lib/libtheora*.a
usr/lib/libtidys.a
usr/lib/libtiff*.a
usr/lib/libunistring.a
usr/lib/libuv.a
usr/lib/libvo-*.a
usr/lib/libvorbisenc.a
usr/lib/libvpx.a
usr/lib/libwmf*.a
usr/lib/libwpd-0.10.a
usr/lib/libwv*.a
usr/lib/libX11.a
usr/lib/libx26*.a
usr/lib/libXaw7.a
usr/lib/libXi.a
usr/lib/libxkbfile.a
usr/lib/libxml2.a
usr/lib/libXmu.a
usr/lib/libxvidcore.a
usr/lib/libyasm.a
usr/lib/libzip.a
usr/lib/python2.6/site-packages/gsf/gnomemodule.a
usr/lib/python2.6/site-packages/gsf/_gsfmodule.a
usr/lib/python2.7/site-packages/ieee1284module.a
usr/lib/xchat/plugins/*.a'

files='
usr/bin/oldfind
usr/bin/ftsfind
bin/mt
bin/mt-GNU
bin/mt-gnu
usr/bin/ogg123
usr/bin/pngfix
usr/bin/png-fix-itxt'

#==============================================================================

if ! [ -d "$1" ] ; then
	echo "$0 <directory>"
	exit 1
fi

cd "$1"
echo
echo "Running $0"
echo

echo "$libs" > /tmp/files2delete.libs

while read i ; do
	[ "$i" ] || continue
	for file in $(echo ./$i) #might cointain wildcards
	do
		[ -f ${file} ] && rm -fv ${file}
	done
done < /tmp/files2delete.libs

if [ -d lib64 ] ; then
	sed 's%/lib/%/lib64/%' /tmp/files2delete.libs > /tmp/files2delete.libs64
	while read i ; do
		[ "$i" ] || continue
		for file in $(echo ./$i) #might cointain wildcards
		do
			[ -f ${file} ] && rm -fv ${file}
		done
	done < /tmp/files2delete.libs64
fi

for i in i386-linux-gnu x86_64-linux-gnu arm-linux-gnueabihf
do
	[ -d lib/$i ] || continue
	sed "s%/lib/%/lib/${i}/%" /tmp/files2delete.libs > /tmp/files2delete.libs.${i}
	while read i ; do
		for file in $(echo ./$i) #might cointain wildcards
		do
			[ -f ${file} ] && rm -fv ${file}
		done
	done < /tmp/files2delete.libs.${i}
done

echo "$files" | \
while read i ; do
	[ "$i" ] || continue
	for file in $(echo ./$i) ; do #might cointain wildcards
		[ -f ${file} ] && rm -fv ${file}
	done
done

echo

### END ###