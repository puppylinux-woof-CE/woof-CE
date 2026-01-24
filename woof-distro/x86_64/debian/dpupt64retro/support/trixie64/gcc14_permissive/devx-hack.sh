echo "For trixie devx: gcc14 permissive"
rm ./sandbox3/rootfs-complete/usr/bin/gcc
cp -vf ./support/trixie64/gcc14_permissive/gcc ./sandbox3/rootfs-complete/usr/bin/
chmod +x ./sandbox3/rootfs-complete/usr/bin/gcc
ln -svf /usr/bin/gcc ./sandbox3/rootfs-complete/usr/bin/cc
