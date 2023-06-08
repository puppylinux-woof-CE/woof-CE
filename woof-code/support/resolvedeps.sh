#!/bin/bash

PKGS_SPECS_TABLE_RESOLVED=0
. $1
[ $PKGS_SPECS_TABLE_RESOLVED -eq 1 ] && exit 0

INSTALLED_PKGS=
NEW_PKGS_SPECS_TABLE=

while read ONEPKGSPEC; do
    case "$ONEPKGSPEC" in
    yes*)
        IFS="|" read -r YESNO GENERICNAME BINARYPARTNAMES FOUR PKGLOCFLD ETC <<< "$ONEPKGSPEC"
        for PKG in ${BINARYPARTNAMES//,/ }; do
            INSTALLED_PKGS="$INSTALLED_PKGS $PKG"
        done
        ;;
    esac
done <<< "$PKGS_SPECS_TABLE"

AUTOCNT=0

while read ONEPKGSPEC; do
    case "$ONEPKGSPEC" in
    yes\|*) ;;
    *) continue ;;
    esac

    IFS="|" read -r YESNO GENERICNAME BINARYPARTNAMES FOUR PKGLOCFLD ETC <<< "$ONEPKGSPEC"

    WITHDEPS=0
    for OPTION in ${ETC//,/ }; do
        [ "$OPTION" != "deps:yes" ] && continue
        WITHDEPS=1
        break
    done

    if [ $WITHDEPS -eq 0 ]; then
        NEW_PKGS_SPECS_TABLE="${NEW_PKGS_SPECS_TABLE}
${ONEPKGSPEC}"
        continue
    fi

    MISSING=
    DEPTH=0

    DEPS="${BINARYPARTNAMES//,/ }"
    while [ -n "$DEPS" ]; do
        NEXTDEPS=

        for DEP in $DEPS; do
            if [ $DEPTH -ne 0 ]; then
                # hack: debdb2pupdb doesn't understand dependency on libsystemd0|liblogind0 and takes the first option
                [ "$DISTRO_BINARY_COMPAT" = "debian" -o "$DISTRO_BINARY_COMPAT" = "devuan" ] && [ "$DEP" = "libsystemd0" ] && DEP="libelogind0"

                # hack: portaudio19-dev depends on libjack-dev|libjack-jackd2-dev but libjack0 and libjack-jackd2-0 conflict
                [ "$DEP" = "libjack-jackd2-0" ] && DEP="libjack0"
                [ "$DEP" = "libjack-jackd2-dev" ] && DEP="libjack-dev"

                FOUND=0
                for PKG in $INSTALLED_PKGS $MISSING; do
                    [ "$PKG" != "$DEP" ] && continue
                    FOUND=1
                    break
                done
                [ $FOUND -eq 1 ] && continue
                echo "adding missing dependency ${DEP} to ${GENERICNAME}"
            fi

            if [ -n "$MISSING" ]; then
                MISSING="$MISSING $DEP"
            else
                MISSING="$DEP"
            fi

            DEPESCAPED="`echo ${DEP} | sed 's/\+/\\\+/g'`"
            ENTRY="`grep -Em1 "^${DEPESCAPED}_[^|]*\|${DEPESCAPED}\|" ${2}`"
            if [ -z "$ENTRY" ]; then
                echo "FATAL: failed to find $DEP."
                exit 1
            fi

            # TODO: we ignore dependency versions, assuming that every compat distro package has exactly one version and it's matching
            NEXTDEPS="$NEXTDEPS `echo $ENTRY | cut -f 9 -d \| | sed -e s/^\+//g -e s/,\+/,/g -e 's/\&[^,]*//g' -e s/,/\ /g`"
        done

        DEPS="$NEXTDEPS"
        DEPTH=$(($DEPTH + 1))
    done

    NEW_PKGS_SPECS_TABLE="${NEW_PKGS_SPECS_TABLE}
yes|${GENERICNAME}|${MISSING// /,}|${FOUR}|${PKGLOCFLD}|${ETC}"
    AUTOCNT=$(($AUTOCNT + 1))

    INSTALLED_PKGS="$INSTALLED_PKGS $MISSING"
done <<< "$PKGS_SPECS_TABLE"

if [ $AUTOCNT -gt 0 ]; then
    cat << EOF >> $1

# after dependency resolution by resolvedeps.sh
PKGS_SPECS_TABLE='
$NEW_PKGS_SPECS_TABLE
'

PKGS_SPECS_TABLE_RESOLVED=1
EOF
else
    echo "Skipped dependency resolution"
fi
