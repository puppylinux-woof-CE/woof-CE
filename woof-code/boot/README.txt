do not remove 'cpio' and 'depmod' as 3builddistro uses them (in sandbox3).
These utilities may not be adequate in the host distro:

- cpio must support the '-H newc' parameter
- depmod must support gzipped modules (Ubuntu Intrepid doesn't!)

do not remove 'boot.msg', 'isolinux.bin' and 'makecpioinitrd' either, again
3builddistro uses them.

Howto extract from a cpio archive
---------------------------------

# gunzip initrd.gz
# mkdir initrd-tree2
# cd initrd-tree2
# cat ../initrd | ../cpio -i -d -m
