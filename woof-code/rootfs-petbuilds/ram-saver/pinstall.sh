patchelf --add-needed libramsaver.so.1 ./`chroot . ldd /bin/bash | grep libc.so.6 | cut -f 3 -d ' '` || exit 1
