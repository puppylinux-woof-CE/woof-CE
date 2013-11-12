BK 13may03:

XFree comes with its own Type1 fonts. I did place the folder
here, but have now removed it, replaced with a symlink to
the Ghostscript Type1 fonts.

Ghostscript installs its own set of Type1 fonts, at
/usr/share/fonts/default/Type1/.

Note also, Mowitz widget library also has its own Type1 fonts, at
/usr/local/share/Mowitz/fonts/ --REMOVED

Note, actually, XFree and Ghostscript full install have
many more font folders. I've cut it way down.

HOWTO:
You will see that misc/ folder has fonts.alias and fonts.dir,
and the scalable fonts such as in Type1/ folder have fonts.dir
and fonts.scale.
You can generate these by cd into the folder, then:
# ttmkfdir > fonts.scale ;no, use mkfontscale
# mkfontdir              ;this one generates fonts.dir
Note that you can add and remove fonts from fonts.dir with a
text editor, but note the count on the first line must be correct.
fonts.alias is edited manually.
Note that for scalable fonts, ttmkdir should be executed before
mkfontdir, as the latter accesses fonts.scale if it exists.

...er, it seems need to use mkfontscale* for Type1 fonts.

BK 24june03:

This folder, /usr/X11R7/lib/X11/fonts/, has three folders,
misc/, TTF/ and Type1/. However I am thinking that the "Luxi"
TrueType fonts in the TTF/ folder are a luxury that Puppy can
do without. So, I've removed it.

We have the Mowitz fonts, why not put a link to those?
So, I have created here Mowitz/, which is a symbolic link to:
/usr/local/share/Mowitz/fonts --REMOVED

The library files /usr/lib/libfreetype.so* are only used by X.
I thought they were used by windowlab*, but I must have changed
something on the last recompile, as not needed now.
I would like to get rid of this also...

Ok, I've overhauled the misc/ folder, hopefully more complete
now. Also made them all iso8859-1.

BK12JUL03:

I have installed, Ted, a wordprocessor, which has its own fonts
folder. Have put a symbolic link here, to it:
/usr/local/afm/.
17JUL: have removed link. it seems to be messing up availability
of the Ghostscript fonts.

BK27MAR04:

Diary/calender app xcal is crashing when click on help button.
Dunno why, but it does give warning msgs:
"Warning: cannot convert string lucidasanstypewriter-12 to type FontStruct"
ditto for lucidasans-10.

So, I have edited misc/fonts.alias to point these to actual fonts.

BK30NOV05:

cursor.pcf-ALT0 is the original cursor font in misc/ folder.
cursor.pcf-ALT1 is an alternative cursor font, to replace that in misc/ folder.
Note, I compiled Kdrive servers with cursor font builtin, so won't use this.

BKNOV06 (v2.12):
Major overhaul! The "Sans" font was mapping to Type1 "Nimbus sans L",
which was the only scalable sans-serif font in Puppy. It comes in
'condensed' and 'normal' but even the normal looks squashed.
So, have intalled Bitstream Vera TTF fonts, see the link here.
The 'TTF' directory is about 1.5M, the 'Type1' dir was about 5.0M
-- but, I have hacked it down to about 1M! -- but need to be
careful, especially check can open all '.ps' and '.pdf' files
-- if not, will have to grab more fonts out of the original 'Type1'
directory.

BK SEPT 2011:
Note that in t2, in the Woof build system the 'fonts' dir is at
rootfs-skeleton/usr/share/X11, but the PET 'zz_t2_fixup' relocates it to
/usr/X11R7/lib/X11/, and /usr/share/X11 becomes a symlink.
