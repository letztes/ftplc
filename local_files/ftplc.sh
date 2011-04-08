#!/bin/bash

#TODO
# * config file that contains
#   * FTPSERVER
#   * USERNAME
#   * PASSWORD

# caveat, sh doesn't know dirname. bash does
SCRIPTS_DIRECTORY=$(dirname $0) 
source $SCRIPTS_DIRECTORY/ftplc.cfg

IMAGES_DIRECTORY=$SCRIPTS_DIRECTORY/images

MINUTES=0 # Counts how long the script is running

FILES_IN_SUBDIRECTORY=0 #Counts how many pictures are in a the current dir
SUBDIR=0 # Name of subdirectory, consists of continuosly incremented digits

SUBDIRS=($(ls -tdr $IMAGES_DIRECTORY/*/ 2> /dev/null))
if [ ${#SUBDIRS[@]} -gt 0 ]; then
    # last element in subdirs array
    GREATEST_SUBDIR=${SUBDIRS[$((${#SUBDIRS[@]}-1))]}
    GREATEST_SUBDIR_BASENAME=$(basename $GREATEST_SUBDIR)
    SUBDIR=$(($GREATEST_SUBDIR_BASENAME+1))
    
fi

# if ./images/0 directory exists, determine the greatest subdirectory name+1
if [ -d $IMAGES_DIRECTORY/$SUBDIR ]; then
    SUBDIR=$(ls -dltr $IMAGES_DIRECTORY/*/ | wc -l)
fi

mkdir $IMAGES_DIRECTORY/$SUBDIR
CURRENT_IMAGES_DIRECTORY=$IMAGES_DIRECTORY/$SUBDIR


sleep $SECONDS_TO_WAIT_FOR_NETWORK #here
# get IP and ISP info once per session
OWN_IP=$(wget -q http://www.whatismyip.com/automation/n09230945.asp -O -);
ISP_INFO=$(whois $OWN_IP | grep 'country:\|address:' | sed 's/^address: //' | sort -u);

touch $CURRENT_IMAGES_DIRECTORY/success.txt
while true; do
    DATETIMESTRING=$(date +"%Y-%m-%dT%H:%M")
    CURRENT_IMAGES_DIRECTORY=$IMAGES_DIRECTORY/$SUBDIR
    WEBCAM_FILENAME=$CURRENT_IMAGES_DIRECTORY/${DATETIMESTRING}_webcam.jpg
    SCREENSHOT_FILENAME=$CURRENT_IMAGES_DIRECTORY/${DATETIMESTRING}_screenshot.jpg

    echo "   taking webcam image..."
    ffmpeg -f video4linux2 -s 1280x800 -r 1 -i /dev/video0 -vframes 1 -f image2 $WEBCAM_FILENAME 2> /dev/null
    timestamp=$(date); convert $WEBCAM_FILENAME -fill white -undercolor '#00000080' -gravity NorthEast -annotate +5+5 "$timestamp\nCurrent IP: $OWN_IP\n\nISP INFO:\n$ISP_INFO" $WEBCAM_FILENAME
    if [ -e $WEBCAM_FILENAME ]; then
        let FILES_IN_SUBDIRECTORY++
    fi
    echo "   done."

    echo "   taking screenshot image..."
    import -display :0.0 -window root $CURRENT_IMAGES_DIRECTORY/screenshot.jpg
    mv $CURRENT_IMAGES_DIRECTORY/screenshot.jpg $SCREENSHOT_FILENAME
    #import -display :0.0 -window root $SCREENSHOT_FILENAME
    if [ -e $SCREENSHOT_FILENAME ]; then
        let FILES_IN_SUBDIRECTORY++
    fi
    echo "   done."

    if [ $(( $MINUTES % $UPLOADINTERVAL )) -eq 0 ]; then
        if test -f $CURRENT_IMAGES_DIRECTORY/success.txt; then
            $SCRIPTS_DIRECTORY/sender.sh $DATETIMESTRING $CURRENT_IMAGES_DIRECTORY &
        fi
    fi
   
    if [ $FILES_IN_SUBDIRECTORY -gt $MAX_FILES_IN_SUBDIRECTORY ]; then
        let SUBDIR++
        mkdir $IMAGES_DIRECTORY/$SUBDIR
        let FILES_IN_SUBDIRECTORY=0
    fi
   
   sleep $CAPTUREINTERVAL
   let MINUTES++
done
