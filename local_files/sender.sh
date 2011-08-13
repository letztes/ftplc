#!/bin/bash
DATETIMESTRING=$1
CURRENT_IMAGES_DIRECTORY=$2

SCRIPTS_DIRECTORY=$(dirname $0) 
source $SCRIPTS_DIRECTORY/ftplc.cfg

if [ $# -lt 2 ]; then
    echo "not enough parameters. DATETIMESTRING and CURRENT_IMAGES_DIRECTORY needed."
    exit
fi
rm $CURRENT_IMAGES_DIRECTORY/success.txt
echo "    uploading files"

ftp -n -i <<ENDOFINPUT
open $FTPSERVER
user $USERNAME $PASSWORD
binary
lcd $CURRENT_IMAGES_DIRECTORY
mput $DATETIMESTRING*".jpg"
get success.txt
close
bye

ENDOFINPUT

if [ -f $CURRENT_IMAGES_DIRECTORY/success.txt ]
then
    rm $CURRENT_IMAGES_DIRECTORY/$DATETIMESTRING"_"*".jpg"
    echo "    remove uploaded files..."
fi

echo "   done."
