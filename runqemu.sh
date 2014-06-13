#!/bin/sh
VGA_TYPE=${VGA_TYPE:-std}
[ "$REDIR" ] && REDIR="-redir tcp:3222::22"
qemu-system-x86_64 -vga $VGA_TYPE -enable-kvm -m 1024 $REDIR -cdrom iso/puppy.iso
