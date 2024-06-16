#!/bin/sh

# Replace placeholder for link to sns.
ln -snf /usr/local/simple_network_setup/sns usr/local/bin/

#Version 3.0:
if [ "$(pwd)" = '/' ]; then
    if [ -e usr/sbin/sns ];then
        if [ ! -L usr/sbin/sns ] \
          || [ "$(readlink usr/sbin/sns)" != "/usr/local/simple_network_setup/sns" ];then
             mv usr/sbin/sns usr/sbin/sns-old.bak
             ln -snf /usr/local/simple_network_setup/sns usr/sbin/
        fi
    fi

    #v3.3 Remove connections if in old format...
    grep -qs '^..[^:]' etc/simple_network_setup/connections \
      && rm -f etc/simple_network_setup/connections

    if ! which iw >/dev/null 2>&1; then
        BACK_TITLE="This version of simple-network-setup cannot manage wireless connections, due to the absence of the 'iw' command in this installation, but can control wired ethernet connections."
        Xdialog --wmclass pgitprep --title "SNS - Barry's Simple Network Setup" --backtitle "$BACK_TITLE" --left --wrap --msgbox "If you need wireless support, either install 'iw' if available or uninstall this package and install or use a 2.4.x version of simple-network-setup." 0 70
    fi

    #v3.4 Remove old udev rule file due to its being renamed.
    rm -f etc/udev/rules.d/51-simple_network_setup.rules
fi
