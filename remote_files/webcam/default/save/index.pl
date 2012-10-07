#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use Template;

use CGI;
use CGI::Carp 'fatalsToBrowser';
my $cgi = CGI->new;
print $cgi->header('text/html');

my $images_directory = './';

my $file = 'overview.tt';
my $vars = {};

my $template = Template->new();

my $timestamp = $cgi->param('timestamp');
my @timestamps_to_delete = $cgi->param('timestamps_to_delete');

=head2
Read from the images directory and extract the timestamp
from each filename. Keep the timestamps unique in an hash.
Return the sorted timestamps.
=cut

sub get_timestamps {
    my %timestamp_of;
    
    opendir(my $images_directory_fh, $images_directory);
    while (my $filename = readdir($images_directory_fh)) {
        next if $filename !~ /^(20\d\d-\d\d-\d\dT\d\d:\d\d).*jpg$/;
        $timestamp_of{$1} = 1;
    }
    closedir $images_directory_fh;
            
    return(sort keys %timestamp_of);
}

sub delete_files {
    
	foreach my $timestamp_to_delete (@timestamps_to_delete) {
	    if (-e $images_directory . $timestamp_to_delete."_screenshot.jpg") {
    		unlink($images_directory . $timestamp_to_delete."_screenshot.jpg");
		}
	    if (-e $images_directory . $timestamp_to_delete."_webcam.jpg") {
    		unlink($images_directory . $timestamp_to_delete."_webcam.jpg");
		}
		if ($timestamp eq $timestamp_to_delete) {
		    $timestamp = "";
		}
	}
    
    return;
}

sub get_current_page_number {
    my ($arg_href) = @_;
    my $i = 1;
    foreach (@{$arg_href->{'timestamps_aref'}}) {
        return $i if $_ eq $arg_href->{'timestamp'};
        $i++;
    }
    return 0;
}

sub main {
    
    delete_files() if $cgi->param('delete');
    
    my @timestamps = get_timestamps();
    
    if (@timestamps) {
        $vars->{'timestamps'} = \@timestamps;
    }
    
    if ($timestamp) {
        $vars->{'timestamp'} = $timestamp;
        $vars->{'screenshot'} = $timestamp."_screenshot.jpg";
        $vars->{'webcam'} = $timestamp."_webcam.jpg";
    }
    
    if ($timestamp and @timestamps) {
        $vars->{'current_page_number'} = get_current_page_number({'timestamp' => $timestamp, 'timestamps_aref' => \@timestamps,});
        $vars->{'total_pages_amount'} = scalar @timestamps;
        
        # -2 because current_page_number starts to count with 1, but array indices start with 0
        $vars->{'previous_timestamp'} = $timestamps[$vars->{'current_page_number'}-2] if $vars->{'current_page_number'} > 1;
        if ($vars->{'current_page_number'} < scalar @timestamps) {
            # current_page_number and not current_page_number+1 because current_page_number starts to count with 1, but array indices start with 0
            $vars->{'next_timestamp'} = $timestamps[$vars->{'current_page_number'}];
        }
            
    }
#die Dumper $vars;
    $template->process($file, $vars)
        or die "Template process failed: ", $template->error(), "\n";
    
    exit;
}

main();
