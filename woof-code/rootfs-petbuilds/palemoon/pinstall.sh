# Set defaultbrowser to run x-www-browser - set the default browser the Debian way, not the Puppy way.
case ${DISTRO_BINARY_COMPAT} in
    ubuntu|trisquel|debian|devuan|raspbian)
        chroot . /usr/bin/update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/palemoon 200
        echo '#!/bin/sh
CMD=$(command -v x-www-browser)
[ -z "$CMD" ] && CMD="/usr/bin/palemoon"
exec "$CMD" "$@"
' > usr/local/bin/defaultbrowser
        ;;
    *)
        echo '#!/bin/sh
exec /usr/bin/palemoon "$@"
' > usr/local/bin/defaultbrowser
        ;;
esac

chmod 755 usr/local/bin/defaultbrowser
cp usr/local/bin/defaultbrowser usr/local/bin/defaulthtmlviewer
