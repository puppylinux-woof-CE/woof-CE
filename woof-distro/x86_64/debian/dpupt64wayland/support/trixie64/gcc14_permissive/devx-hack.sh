echo "For trixie devx: gcc14 permissive"
cp -vf ./support/gcc14_permissive/gcc ./sandbox3/devx/usr/bin/
chmod +x ./sandbox3/devx/usr/bin/gcc
ln -svf /usr/bin/gcc ./sandbox3/devx/usr/bin/cc
