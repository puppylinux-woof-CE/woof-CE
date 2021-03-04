#!/bin/sh -e

command_qemu() {
    echo "$1" >> /tmp/qemu.in
}

wait_for_screenshot() {
    rm -f /tmp/screenshot.pnm /tmp/screenshot-masked.bmp
    sleep 1
    i=1
    while :; do
        [ -n "$GITHUB_ACTIONS" ] || /bin/echo -ne "\033[H"
        [ -f /tmp/screenshot.pnm ] && img2txt -d none -H 24 /tmp/screenshot.pnm
        if [ -n "$GITHUB_ACTIONS" ]; then
            echo "Waiting for $1 (${i}s) ... "
        else
            echo -n "Waiting for $1 (${i}s) ... "
        fi
        command_qemu "screendump /tmp/screenshot.pnm"
        sleep 1
        composite -compose atop mask.xpm /tmp/screenshot.pnm /tmp/screenshot-masked.bmp
        ! cmp /tmp/$1.bmp /tmp/screenshot-masked.bmp > /dev/null || break
        i=$(($i + 1))
    done
}

[ -p /tmp/qemu.in ] || mkfifo /tmp/qemu.in
[ -p /tmp/qemu.out ] || mkfifo /tmp/qemu.out

if [ -n "$GITHUB_ACTIONS" ]; then
    qemu-system-x86_64 -m 512 -drive format=raw,file=$1 -monitor pipe:/tmp/qemu -vga cirrus -display none &
else
    qemu-system-x86_64 -m 512 -drive format=raw,file=$1 -monitor pipe:/tmp/qemu -vga cirrus &
fi

trap "command_qemu quit" EXIT INT TERM

for SHOT in *.pnm; do
    convert ${SHOT} /tmp/${SHOT%.pnm}.bmp
done

[ -n "$GITHUB_ACTIONS" ] || /bin/echo -ne "\033[2J\033[H"

# wait until the desktop is ready
wait_for_screenshot quicksetup

command_qemu "sendkey alt-f4"
wait_for_screenshot welcome1stboot

command_qemu "sendkey alt-f4"
wait_for_screenshot desktop

command_qemu "sendkey ctrl-alt-t"
wait_for_screenshot terminal

for c in d e f a u l t b r o w s e r; do
    command_qemu "sendkey $c"
done
command_qemu "sendkey ret"
wait_for_screenshot browser

command_qemu "sendkey ctrl-t"
wait_for_screenshot tab