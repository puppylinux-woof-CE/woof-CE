#!/bin/bash

. $1

INSTALLED_PKGS=
NEW_PKGS_SPECS_TABLE=

while read LINE; do
    case "$LINE" in
    yes*|auto*)
        IFS="|" read -r F1 F2 F3 F4 <<< "$LINE"
        for PKG in ${F3//,/ }; do
            INSTALLED_PKGS="$INSTALLED_PKGS $PKG"
        done
        ;;
    esac
done <<< "$PKGS_SPECS_TABLE"

AUTOCNT=0

while read LINE; do
    case "$LINE" in
    auto\|*) ;;
    yes\|*)
        NEW_PKGS_SPECS_TABLE="${NEW_PKGS_SPECS_TABLE}
${LINE}"
        continue
        ;;
    *) continue ;;
    esac

    IFS="|" read -r F1 F2 F3 F4 <<< "$LINE"
    MISSING=
    DEPTH=0

    DEPS="${F3//,/ }"
    while [ -n "$DEPS" ]; do
        NEXTDEPS=

        for DEP in $DEPS; do
            if [ $DEPTH -ne 0 ]; then
                FOUND=0
                for PKG in $INSTALLED_PKGS $MISSING; do
                    [ "$PKG"  != "$DEP" ] && continue
                    FOUND=1
                    break
                done
                [ $FOUND -eq 1 ] && continue
                echo "adding missing dependency ${DEP} to ${F2}"
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
yes|${F2}|${MISSING// /,}|${F4}"
    AUTOCNT=$(($AUTOCNT + 1))

    INSTALLED_PKGS="$INSTALLED_PKGS $MISSING"
done <<< "$PKGS_SPECS_TABLE"

if [ $AUTOCNT -gt 0 ]; then
    cat << EOF >> $1

# after dependency resolution by resolvedeps.sh
PKGS_SPECS_TABLE='
$NEW_PKGS_SPECS_TABLE
'
EOF
else
    echo "Skipped dependency resolution"
fi
