echo "For resolute devx: gcc permissive"
cp -vf ./support/gcc_permissive/gcc ./sandbox3/devx/usr/bin/
chmod +x ./sandbox3/devx/usr/bin/gcc
ln -svf /usr/bin/gcc ./sandbox3/devx/usr/bin/cc
