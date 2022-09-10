#!/bin/sh

echo "Setting up SIP profile"
mkdir -p /root/.config/jami
cp /etc/ccs/dring.yml  /root/.config/jami/
echo "Overwriting jwm tray"
cp /etc/ccs/jwm* /root/.jwm/
echo "Setting wallpaper"
cat << EOF > /root/.jwm/jwmrc-wallpaper
<?xml version="1.0"?>

<JWM>

<Desktops>
  <Background type="image">/usr/share/bliss.svg</Background>
</Desktops>
</JWM>
EOF
