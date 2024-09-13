echo "For trixie devx: gcc14 permissive"
cp -vf ./support/gcc14_permissive/gcc ./sandbox3/devx/usr/bin/
ln -vf /usr/bin/gcc .sandbox3/devx/usr/bin/cc
