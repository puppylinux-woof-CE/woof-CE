BK 7Sept03:

I upgraded Ghostscript from v6.50 to 8.11, but have
kept the previous Type1 fonts. However, the new gs
can't find them. So put this link here:

# ln -s /usr/share/fonts/default/Type1 fonts

Also, look down into 8.11/Resources folder, I have
left out lots of stuff. In particular, the entire
"CMap" folder.
