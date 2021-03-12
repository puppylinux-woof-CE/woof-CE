#!/bin/sh

timeout 900 ./test.sh $1
ret=$?

if [ $ret -eq 0 ]; then
    echo "Tests passed!"
elif [ -f /tmp/screenshot-masked.bmp ]; then
    echo "Tests failed! Last screeenshot:"
    cat /tmp/screenshot-masked.bmp | xz -9 | base64
else
    echo "Tests failed!"
fi

exit $ret