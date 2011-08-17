<?php

$current_page_number = 'unknown'; # convenient displaying of pagenumber

$timestamp = $_GET['timestamp'];
$save = $_GET['save'];
$delete = $_GET['delete'];

//print "$timestamp";
$timestamps = array();
$image_filenames = array();
$directory = ".";

$handle = opendir($directory);


while ($file = readdir($handle)) {
    if (substr($file,-3,3) == 'jpg' and substr($file, 0, 2) == 20) {
    	array_push($image_filenames, $file);
	    if (substr($file,-7,7) == 'hot.jpg' and substr($file, 0, 2) == 20) {
	        $current_timestamp = substr($file, 0, 16);
	        array_push($timestamps, $current_timestamp);
	    }
    }
}
sort($timestamps);

print '
<html>
    <head><title>untitled document</title></head>
    <body bgcolor="#ddddff"
    <h1>Gesicherte Bilder</h1>
';

# Button for deleting all images and another Button for saving the current image
print '<a href="../index.php"><input value="Ungesichtetes Material" type="button"></a>&nbsp;
       <a href="index.php?delete='.$timestamp.'"><input value="Diese Seite l&ouml;schen" type="button" onClick="return confirm(\'Wirklich diese Seite l&ouml;schen?\');"></a><br/>';

# A div for the links on the left side
print '

    <div style="float:left">
';

    foreach ($timestamps as $current_timestamp) {
        print "<a href='index.php?timestamp=$current_timestamp'>$current_timestamp</a><br />";
        # if page number is still unknown, try to find it out
        if ($timestamp and $current_page_number == 'unknown') {
            $i++;
            if ($timestamp == $current_timestamp) {
                $current_page_number = $i;
            }
        }
    }
print '
    </div>
    <div style="border:3px black dotted; float:left">
    
';
##
if ($delete) {
    $timestamp = $delete;
	unlink($timestamp.'_webcam.jpg');
	unlink($timestamp.'_screenshot.jpg');
	print '<h1>Diese Seite wurde gel&ouml;scht.</h1>';
}
if ($timestamp) {
    print 'Seite '.$current_page_number.' von '.(count($timestamps)).'<br/>';
    print '
            <table>
                <th>Webcam</th>
                <th>Screenshot</th>
                <tr>
                    <td><a href="./'.$timestamp.'_webcam.jpg"><img src="./'.$timestamp.'_webcam.jpg" height="480" /></td>
                    <td><a href="./'.$timestamp.'_screenshot.jpg"><img src="./'.$timestamp.'_screenshot.jpg" height="480" ></a></td>
                </tr>
            </table>
            <br />
    ';
    
    $previous_timestamp = 'nothing';
    $current_timestamp = 'nothing';
    print "<a href='index.php?timestamp=".$timestamps[0]."'><input value='".$timestamps[0]." << ' type='button'></a> ... ";
    
    # If current file is first in array
    if ($timestamp == $timestamps[0]) {
        $current_timestamp = $timestamps[0];
        $next_timestamp = $timestamps[1];
        print "&emsp;&emsp;nothing&emsp;&emsp;";
        print "<a href='index.php?timestamp=$current_timestamp'><input value='$current_timestamp' type='button'></a> ";
        print "<a href='index.php?timestamp=$next_timestamp'><input value=' > $next_timestamp' type='button'></a> ";
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
}
//<input value='$current_timestamp' type='button'>

print '
    </body>
</html>
';


?>
