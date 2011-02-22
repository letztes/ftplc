#!/bin/bash

# in ubuntu 10.10 maverick it seems not to work to take screenshots from
# cron: the script is then unable to open display from X server
# so the script runs as automatic started programs in X-session

 
IMAGES_DIRECTORY=/opt/.opt/images # change to a value that fits your system
SCRIPTS_DIRECTORY=/opt/.opt # this is where this script is in. change at will

MINUTES=0 # Counts how long the script is running
UPLOADINTERVAL=10 # Value in minutes

# in case the network is not yet up, sleep a little
sleep 30
# get IP and ISP info once per session
OWN_IP=$(wget -q http://www.whatismyip.com/automation/n09230945.asp -O -);
ISP_INFO=$(whois $OWN_IP | grep 'country:\|address:' | sed 's/^address: //' | sort -u);

touch $IMAGES_DIRECTORY/success.txt
while true; do
    DATETIMESTRING=$(date +"%Y.%m.%dT%H:%M")
    WEBCAM_FILENAME=$IMAGES_DIRECTORY/${DATETIMESTRING}_webcam.jpg
    SCREENSHOT_FILENAME=$IMAGES_DIRECTORY/${DATETIMESTRING}_screenshot.jpg

    echo "   taking webcam image..."
    ffmpeg -f video4linux2 -s 1280x800 -r 1 -i /dev/video0 -vframes 1 -f image2 $WEBCAM_FILENAME 2> /dev/null
    timestamp=$(date); convert $WEBCAM_FILENAME -fill white -undercolor '#00000080' -gravity NorthEast -annotate +5+5 "$timestamp\nCurrent IP: $OWN_IP\n\nISP INFO:\n$ISP_INFO" $WEBCAM_FILENAME 
    echo "   done."

    echo "   taking screenshot image..."
    import -display :0.0 -window root $IMAGES_DIRECTORY/screenshot.jpg
    mv $IMAGES_DIRECTORY/screenshot.jpg $SCREENSHOT_FILENAME
    #import -display :0.0 -window root $SCREENSHOT_FILENAME
    echo "   done."

    if [ $(( $MINUTES % $UPLOADINTERVAL )) -eq 0 ]; then
        if test -f $IMAGES_DIRECTORY/success.txt; then
            #$IMAGES_DIRECTORY/ftplc.sh $DATETIMESTRING $IMAGES_DIRECTORY &
            $SCRIPTS_DIRECTORY/sender.sh $DATETIMESTRING $IMAGES_DIRECTORY &
        fi
   fi
   sleep 60
   let MINUTES++
done
