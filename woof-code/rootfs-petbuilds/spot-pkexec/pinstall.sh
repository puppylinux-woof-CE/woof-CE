echo "Moving Downloads to /home/spot"
if [ -e home/spot/Downloads ]; then
	rm -rf root/Downloads
else
	mv root/Downloads home/spot/
fi
chroot . chown -R spot:spot /home/spot/Downloads
ln -s ../home/spot/Downloads root/
