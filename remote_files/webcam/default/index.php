<?php

##############################################################################
# Caveat
#
# The submit button is only for deleting the selected images.
# Navigating through images and saving an image is done with link-buttons.
##############################################################################

touch('success.txt');


##############################################################################
# Set Variables
##############################################################################

$current_page_number = 'unknown'; # convenient displaying of pagenumber

$timestamp = $_GET['timestamp'];
$save = $_GET['save'];
$delete = $_GET['delete'];
$timestamps_to_delete = $_GET['timestamps_to_delete'];

$timestamps = array();

$timestamps = get_timestamps(); # selfmade function, see below



##############################################################################
# Display the beginning of the webpage
##############################################################################

print '
<html>
    <head>
        <title>untitled document</title>
        <script type = "text/javascript">
            function checkAll() {
                if(document.forms[0].masterbox.checked==true){
                    last_index = document.forms[0].elements["timestamps_to_delete[]"].length;
                    if (last_index > 20) {last_index = 20;}
                    for(var i=0; i< last_index; i++) {
                        document.forms[0].elements["timestamps_to_delete[]"][i].checked=true;
                        
                    }
                }
                else {
                    for(var i=0; i< document.forms[0].elements["timestamps_to_delete[]"].length; i++) {
                        document.forms[0].elements["timestamps_to_delete[]"][i].checked=false;
                    }
                }
            }
        </script>
    </head>
    <body bgcolor="#ddffdd">
    <h1>Ungesichtetes Material</h1>
    <form action="index.php" method="get">
';


##############################################################################
# Delete selected images
##############################################################################

if ($delete) {
	foreach ($timestamps_to_delete as $timestamp_to_delete) {
	    if (file_exists($timestamp_to_delete."_screenshot.jpg")) {
    		unlink($timestamp_to_delete."_screenshot.jpg");
		}
	    if (file_exists($timestamp_to_delete."_webcam.jpg")) {
    		unlink($timestamp_to_delete."_webcam.jpg");
		}
		if ($timestamp == $timestamp_to_delete) {
		    $timestamp = "";
		}
	}

    print '
        <h1>Fertig. Alle ausgew&auml;hlten Bilder gel&ouml;scht.</h1>
    ';
    $timestamps = get_timestamps(); # selfmade function, see below
    
    print "<a href='index.php'><input value='Zur&uuml;ck zur &Uuml;bersicht' type='button'></a> ";
}


##############################################################################
# Save current displayed image
##############################################################################

if ($save) {
	$timestamp = $save;
	copy($timestamp.'_webcam.jpg', 'save/'.$timestamp.'_webcam.jpg');
	copy($timestamp.'_screenshot.jpg', 'save/'.$timestamp.'_screenshot.jpg');
}


##############################################################################
# Display on the left side the links to the images
##############################################################################

# A div for the links on the left side
if ($timestamps) {
    print '

        <div style="float:left">
    ';
    print '<input type="checkbox" name="masterbox" onclick="checkAll()" value="">Alle ausw&auml;hlen<br />';
    $i = 0;
    foreach ($timestamps as $current_timestamp) {
        print "<input type=\"checkbox\" name=\"timestamps_to_delete[]\" value=\"$current_timestamp\"><a href='index.php?timestamp=$current_timestamp'>$current_timestamp</a><br />";
        # if page number is still unknown, try to find it out
        if ($timestamp and $current_page_number == 'unknown') {
            $i++;
            if ($timestamp == $current_timestamp) {
                $current_page_number = $i;
            }
        }
    }

    ##########################################################################
    # Display the button for deleting all images
    ##########################################################################

    print '
    <input type="hidden" name="delete" value="yes" />
    <input type="hidden" name="timestamp" value="'.$timestamp.'" />
    <input value="Alle Bilder l&ouml;schen" type="submit" onClick="return confirm(\'Wirklich alle Bilder l&ouml;schen?\');" /><br />
    </form>';
}

##############################################################################
# Display the images, the buttons for navigating and the delete button
##############################################################################
if ($timestamp) {

    print '
        </div>
        <div style="border:3px black dotted; float:left">
        
    ';
    
    $previous_timestamp = 'nothing';
    $current_timestamp = 'nothing';
    
    ##########################################################################
    # Display the number of the image in the number of total images
    ##########################################################################
    print 'Seite '.$current_page_number.' von '.(count($timestamps)).'<br/>';
    print "<a href='index.php?timestamp=".$timestamps[0]."'><input value='".$timestamps[0]." << ' type='button'></a> ... ";


    ##########################################################################
    # Display the buttons for navigating
    ##########################################################################
    # If current file is first in array
    if ($timestamp == $timestamps[0]) {
        $current_timestamp = $timestamps[0];
        $next_timestamp = $timestamps[1];
        print "&emsp;&emsp;nothing&emsp;&emsp;";
        print "<a href='index.php?timestamp=$current_timestamp'><input value='$current_timestamp' type='button'></a> ";
        if (! $next_timestamp) {
            print "&emsp;&emsp;nothing&emsp;&emsp;";
        }
        else {
            print "<a href='index.php?timestamp=$next_timestamp'><input value=' > $next_timestamp' type='button'></a> ";
        }
        reset($timestamps);
    }
    # If current file is last in array
    elseif ($timestamp == end($timestamps)) {
        $current_timestamp = end($timestamps);
        $previous_timestamp = prev($timestamps);
        print "<a href='index.php?timestamp=$previous_timestamp'><input value='$previous_timestamp < ' type='button'></a> ";
        print "<a href='index.php?timestamp=$current_timestamp'><input value='$current_timestamp' type='button'></a> ";
        print "&emsp;&emsp;nothing&emsp;&emsp;";
        reset($timestamps);
    }
    else {
        foreach ($timestamps as $next_timestamp) {
            if ($current_timestamp == $timestamp) {
                if ($previous_timestamp == 'nothing') {
                    print 'nothing';
                }
                else {
                    print "<a href='index.php?timestamp=$previous_timestamp'><input value='$previous_timestamp < '  type='button'></a> ";
                }
                if ($current_timestamp == 'nothing') {
                    print 'nothing';
                }
                else {
                    print "<a href='index.php?timestamp=$current_timestamp'><input value='$current_timestamp' type='button'></a> ";
                }
                print "<a href='index.php?timestamp=$next_timestamp'><input value=' > $next_timestamp' type='button'></a> ";
                break;
            }
            $previous_timestamp = $current_timestamp;
            $current_timestamp = $next_timestamp;
        }
    }
    print " ... <a href='index.php?timestamp=".end($timestamps)."'><input value=' >> ".end($timestamps)."' type='button'></a>";
print '<div  align="right"><a href="index.php?save='.$current_timestamp.'"><input value="Diese Seite sichern" type="button"></a></div>';

##############################################################################
# Display the current selected images
##############################################################################
    print '
        <table>
            <th>Webcam</th>
            <th>Screenshot</th>
            <tr>
                <td><a href="./'.$timestamp.'_webcam.jpg"><img src="./'.$timestamp.'_webcam.jpg" height="480" /></a></td>
                <td><a href="./'.$timestamp.'_screenshot.jpg"><img src="./'.$timestamp.'_screenshot.jpg" height="480" ></a></td>
            </tr>
        </table>
        <br />
    ';


    print '
    </body>
</html>
';
}


?>

<?php

##############################################################################
# Selfmade functions
##############################################################################

function get_timestamps() {
    $timestamps = array();
    $image_filenames = array();
    $directory = ".";

    $handle = opendir($directory);

    while ($file = readdir($handle)) {
        if (substr($file,-3,3) == 'jpg' and substr($file, 0, 2) == 20) {
        	array_push($image_filenames, $file);
            $current_timestamp = substr($file, 0, 16);
            array_push($timestamps, $current_timestamp);
        }
    }
    $timestamps_unique = array_unique($timestamps);
    sort($timestamps_unique);
    return($timestamps_unique);
}
?>
