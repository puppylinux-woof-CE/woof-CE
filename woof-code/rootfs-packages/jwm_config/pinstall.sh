#!/bin/sh

. etc/DISTRO_SPECS

rm -f root/.jwm/jwmrc-personal_old

( cd usr/local/jwm_config; ln -sf ../bin/timebar time )

# windows are slow to move or resize if drawing is slow
case "${DISTRO_TARGETARCH}" in
    x86*) ;;
    *) sed 's/>opaque</>outline</g' -i root/.jwm/jwmrc-personal root/.jwm/backup/jwmrc-personal ;;
esac
