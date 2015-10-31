#!/bin/sh
for dtop in switch2 GTK-Chtheme icon_switcher; do
    [ -f "usr/share/applications/${dtop}.desktop" ] || continue
    if grep -q "^NoDisplay" usr/share/applications/${dtop}.desktop; then
        sed -i 's%NoDisplay=.*%NoDisplay=true%' usr/share/applications/${dtop}.desktop
    else
        echo 'NoDisplay=true' >> usr/share/applications/${dtop}.desktop
    fi
done
