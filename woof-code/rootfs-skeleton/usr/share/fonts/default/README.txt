BK 13may03:

Fonts are a problem with Linux!
XFree has its own Adobe Type1 fonts in /usr/X11R7/lib/X11/fonts/type1/.
Mowitz library has Type1 fonts in /usr/local/share/Mowitz/fonts/.
Ghostview has its own set here.
I tried setting environment variable GS_FONTPATH to point to the
XFree fonts. I set this is /etc/profile. Ghostscript uses this variable
after looking in its standard places:
/usr/share/fonts/default/Type1
/usr/local/share/ghostscript/6.50/lib
/usr/share/ghostscript/fonts

I got an error when tried to run gs* with only the XFree fonts.
Maybe need to setup a fonts.alias file appropriately...

20may03:

I have removed the XFree Type1 directory, replaced with a symbolic
link to the Ghostscript Type1 fonts. This saves some space.

note, Mowitz library removed from Puppy.

7Sept03:

Have upgraded gs from 6.50 to 8.11. Placed a link from
/usr/local/share/ghostscript/fonts to here so that new
gs can find the fonts.

NOV06 (v2.12):
Major overhaul! The "Sans" font was mapping to Type1 "Nimbus sans L",
which was the only scalable sans-serif font in Puppy. It comes in
'condensed' and 'normal' but even the normal looks squashed.
So, have intalled Bitstream Vera TTF fonts, see the link here.
The 'TTF' directory is about 1.5M, the 'Type1' dir was about 5.0M
-- but, I have hacked it down to about 1M! -- but need to be
careful, especially check can open all '.ps' and '.pdf' files
-- if not, will have to grab more fonts out of the original 'Type1'
directory.
Now, 'Sans' defaults to a Bitstream TTF font, looks very nice.

V2.14:
On some web pages, DejaVu fonts do not render properly. Ligatures such
as 'ffi' and 'fi' overlap but are not supposed to when separate chars.
I applied a patch to the DejaVu v2.13 .sfd source and generated .ttf files.
This patch turns off the ligatures. (sources044)

------------------
Woof, June 13 2010

Have updated DejaVu sans fonts, v5.31

Compiled from source with hacked Makefile to only create "LGC" reduced fonts but
retain proper font naming without "LGC". 
Manually install to /usr/share/fonts/default/TTF/

And in that dir run:
# mkfontscale
# mkfontdir

fc-cache also needs to be run, but i have done that in 3builddistro.
