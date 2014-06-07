#! /bin/bash

ls -lha | grep "^d" | awk '{print "stock_folder|" $1 "|" $9}'
ls -lha | grep "^-" | awk '{print "file-executable|" $1 "|" $9}'

