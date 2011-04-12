#!/bin/bash

#TODO

# caveat, sh doesn't know dirname. bash does
SCRIPTS_DIRECTORY=$(dirname $0) 
source $SCRIPTS_DIRECTORY/ftplc.cfg

IMAGES_DIRECTORY=$SCRIPTS_DIRECTORY/images

MINUTES=0 # Counts how long the script is running

FILES_IN_SUBDIRECTORY=0 #Counts how many pictures are in a the current dir
SUBDIR=$(date +"%Y-%m-%dT%H:%M")
mkdir $IMAGES_DIRECTORY/$SUBDIR
CURRENT_IMAGES_DIRECTORY=$IMAGES_DIRECTORY/$SUBDIR


############################################################################
#
# Get own IP-address once
#
############################################################################

sleep $SECONDS_TO_WAIT_FOR_NETWORK
OWN_IP=$(wget -q http://www.whatismyip.com/automation/n09230945.asp -O -);
ISP_INFO=$(whois $OWN_IP | grep 'country:\|address:' | sed 's/^address: //' | sort -u);


############################################################################
#
# Infinite loop wherein images are taken und uploaded
#
############################################################################

touch $CURRENT_IMAGES_DIRECTORY/success.txt
while true; do

    ########################################################################
    #
    # Set variable names for current loop
    #
    ########################################################################

    DATETIMESTRING=$(date +"%Y-%m-%dT%H:%M")
    CURRENT_IMAGES_DIRECTORY=$IMAGES_DIRECTORY/$SUBDIR
    WEBCAM_FILENAME=$CURRENT_IMAGES_DIRECTORY/${DATETIMESTRING}_webcam.jpg
    SCREENSHOT_FILENAME=$CURRENT_IMAGES_DIRECTORY/${DATETIMESTRING}_screenshot.jpg


    ########################################################################
    #
    # Take the webcam image
    #
    ########################################################################

    echo "   taking webcam image..."
    ffmpeg -f video4linux2 -s 1280x800 -r 1 -i /dev/video0 -vframes 1 -f image2 $WEBCAM_FILENAME 2> /dev/null
    timestamp=$(date); convert $WEBCAM_FILENAME -fill white -undercolor '#00000080' -gravity NorthEast -annotate +5+5 "$timestamp\nCurrent IP: $OWN_IP\n\nISP INFO:\n$ISP_INFO" $WEBCAM_FILENAME
    if [ -e $WEBCAM_FILENAME ]; then
        let FILES_IN_SUBDIRECTORY++
    fi
    echo "   done."
    
    
    ########################################################################
    #
    # Take the screenshot image
    #
    ########################################################################

    echo "   taking screenshot image..."
    import -display :0.0 -window root /tmp/screenshot.jpg
    mv /tmp/screenshot.jpg $SCREENSHOT_FILENAME
    #import -display :0.0 -window root $SCREENSHOT_FILENAME
    if [ -e $SCREENSHOT_FILENAME ]; then
        let FILES_IN_SUBDIRECTORY++
    fi
    echo "   done."
    
    ########################################################################
    #
    # Upload the screenshot and webcam image via sender.sh
    #
    ########################################################################

    if [ $(( $MINUTES % $UPLOADINTERVAL )) -eq 0 ]; then
        if test -f $CURRENT_IMAGES_DIRECTORY/success.txt; then
            $SCRIPTS_DIRECTORY/sender.sh $DATETIMESTRING $CURRENT_IMAGES_DIRECTORY &
        fi
    fi
   
   
    ########################################################################
    #
    # Make a new current local directory if the other is too full already
    #
    ########################################################################

    if [ $FILES_IN_SUBDIRECTORY -gt $MAX_FILES_IN_SUBDIRECTORY ]; then
        SUBDIR=$(date +"%Y-%m-%dT%H:%M")
        mkdir $IMAGES_DIRECTORY/$SUBDIR
        let FILES_IN_SUBDIRECTORY=0
    fi
   
   sleep $CAPTUREINTERVAL
   let MINUTES++
done
