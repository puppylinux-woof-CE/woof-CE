This directory contains template files for menus.

For example, JWM window manager has a configuration file /root/.jwmrc
and this contains the specs for the menu layout and entries.
/etc/xdg/templates/_root_.jwmrc has this configuration file in a raw form.
Notice the naming of the file: the '_' will get converted to '/' to determine
the detination of the config file.

The script /usr/sbin/fixmenus processes any template files it finds in
/etc/xdg/templates and generates the destination config files.
The template files have special lines embedded into them that have the
keyword 'PUPPYMENU' embedded into them, that are executable lines for
generating the entries from the XDG menu information.