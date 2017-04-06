#!/bin/sh
#------------------------------------------------
# woof pinstall.sh for ca-certificates compat pkg

CWD="`pwd`"
cd ./usr/share/ca-certificates
find -type f | cut -c 3- > ../../../etc/ca-certificates.conf
cd "$CWD"

# From update-ca-certificates...
# Edited to work in cross builds.

CERTSCONF=${CWD}/etc/ca-certificates.conf
CERTSDIR=${CWD}/usr/share/ca-certificates
CERTBUNDLE=ca-certificates.crt
ETCCERTSDIR=${CWD}/etc/ssl/certs

# Helper files.  (Some of them are not simple arrays because we spawn
# subshells later on.)
TEMPBUNDLE="$(mktemp -t "${CERTBUNDLE}.tmp.XXXXXX")"

# Adds a certificate to the list of trusted ones.  This includes a symlink
# in /etc/ssl/certs to the certificate file and its inclusion into the
# bundle.
add() {
  CERT="$1"
  PEM="$ETCCERTSDIR/$(basename "$CERT" .crt | sed -e 's/ /_/g' \
                                                  -e 's/[()]/=/g' \
                                                  -e 's/,/_/g').pem"
  if ! test -e "$PEM" || [ "$(readlink "$PEM")" != "$CERT" ]
   then
    ln -sf "$CERT" "$PEM"
  fi
  # Add trailing newline to certificate, if it is missing (#635570)
  sed -e '$a\' "$CERT" >> "$TEMPBUNDLE"
}

cd $ETCCERTSDIR
echo -n "Updating certificates in $ETCCERTSDIR... "

sed -e '/^$/d' -e '/^#/d' -e '/^!/d' $CERTSCONF | while read crt
do
  if ! test -f "$CERTSDIR/$crt"
  then
   echo "W: $CERTSDIR/$crt not found, but listed in $CERTSCONF." >&2
   continue
  fi
  add "$CERTSDIR/$crt"
done

rm -f "$CERTBUNDLE"

c_rehash . > /dev/null

chmod 0644 "$TEMPBUNDLE"
mv -f "$TEMPBUNDLE" "$CERTBUNDLE"

# END OF ca-certicates pinstall.sh ..
#------------------------------------------------
