#!/bin/bash

#TODO

# caveat, sh doesn't know dirname. bash does
SCRIPTS_DIRECTORY=$(dirname $0) 
source $SCRIPTS_DIRECTORY/ftplc.cfg

MINUTES=0 # Counts how long the script is running

SUBDIR=$(date +"%Y-%m-%dT%H:%M")
mkdir $IMAGES_DIRECTORY/$SUBDIR
CURRENT_IMAGES_DIRECTORY=$IMAGES_DIRECTORY/$SUBDIR


############################################################################
#
# Get own IP-address once
#
############################################################################

# Sometimes the network is not up immediately. Wait a little.
sleep $SECONDS_TO_WAIT_FOR_NETWORK

OWN_IP=$(wget -q http://sedetiam.de/ip/ -O -);
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
    avconv -f video4linux2 -s 1280x800 -r 1 -i /dev/video0 -vframes 1 -f image2 $WEBCAM_FILENAME 2> /dev/null
    if [ -e $WEBCAM_FILENAME ]; then
        timestamp=$(date); convert $WEBCAM_FILENAME -fill white -undercolor '#00000080' -gravity NorthEast -annotate +5+5 "$timestamp\nCurrent IP: $OWN_IP\n\nISP INFO:\n$ISP_INFO" $WEBCAM_FILENAME
        echo "   done."
    else
        echo "   not possible."
    fi
    
    
    ########################################################################
    #
    # Take the screenshot image
    #
    ########################################################################

    echo "   taking screenshot image..."
    import -display :0.0 -window root /tmp/screenshot.jpg
    # import cannot use variables as file arguments
    mv /tmp/screenshot.jpg $SCREENSHOT_FILENAME
    if [ -e $SCREENSHOT_FILENAME ]; then
        echo "   done."
    else
        echo "   not possible."
    fi
    
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
    # Upload and remove all images via allsender.pl if
    # there is more than a certain amount of images
    #
    ########################################################################
        
    if [ $(ls -R $IMAGES_DIRECTORY | grep jpg | wc -l) -gt $MAX_FILES_AT_ALL ]; then
        if [ -f $CURRENT_IMAGES_DIRECTORY/success.txt ]; then
            CURRENT_SUBDIRECTORIES=$(ls $IMAGES_DIRECTORY)
            perl $SCRIPTS_DIRECTORY/allsender.pl $CURRENT_SUBDIRECTORIES
            SUBDIR=$(date +"%Y-%m-%dT%H:%M")
            mkdir $IMAGES_DIRECTORY/$SUBDIR
            CURRENT_IMAGES_DIRECTORY=$IMAGES_DIRECTORY/$SUBDIR
            touch $CURRENT_IMAGES_DIRECTORY/success.txt
        fi
    fi
   
   sleep $CAPTUREINTERVAL
   let MINUTES++
done
