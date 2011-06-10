#!/usr/bin/perl

use CGI;

print "Content-type: text\n\n";
print $ENV{'REMOTE_ADDR'};
