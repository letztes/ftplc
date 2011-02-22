#!/bin/bash
DATETIMESTRING=$1
IMAGES_DIRECTORY=$2

FTPSERVER='' # put your ftp server name here
USERNAME='' # put the user name of your ftp server here
PASSWORD='' # put the password the user of your ftp server here

if [ $# -lt 2 ]; then
    echo "not enough parameters, shame on you!"
    exit
fi
rm $IMAGES_DIRECTORY/success.txt
echo "    uploading files"

ftp -n -i <<ENDOFINPUT
open $FTPSERVER
user $USERNAME $PASSWORD
cd webcam
binary
lcd $IMAGES_DIRECTORY
put $DATETIMESTRING"_screenshot.jpg"
put $DATETIMESTRING"_webcam.jpg"
get success.txt
close
bye

ENDOFINPUT

echo "   done."
