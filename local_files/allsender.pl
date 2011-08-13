#!/usr/bin/perl

=head1
    Ich hätte das ganze von Anfang an in Perl schreiben sollen.
=cut

use warnings;
use strict;

use Data::Dumper;
use File::Path;
use Net::FTP;

=head2
    Returns a hashref.
    $directory_tree_href->{/any/dir}->{<timestamp>} = [qw(<img.jpg> <img.jpg>)]
                               ^             ^                ^          ^
                          directory      directory           file       etc. 
=cut
sub get_directory_structure {
    my %args                = @_;
    my $config_href         = $args{'config_href'};

    my %directory_tree;
    my $dir_handle;

    foreach my $curdir (@ARGV) {
        next if $curdir !~ m/\dT\d/;
        next if not -d "$config_href->{'images_directory'}/$curdir";
        my $another_dir_handle;
        opendir($another_dir_handle, "$config_href->{'images_directory'}/$curdir");
        $directory_tree{$curdir} = [grep(/jpg/,readdir($another_dir_handle))];
        closedir($another_dir_handle);
    }
    return \%directory_tree;
}

=head2
    Uploads the directories recursively.
=cut
sub upload_all_images {
    my %args                = @_;
    my $directory_tree_href = $args{'directory_tree_href'};
    my $ftp                 = $args{'ftp'};
    my $config_href         = $args{'config_href'};
    
    if (not %{$directory_tree_href}) {
        print "allsender.pl: no local files to upload\n";
        return;
    }
    
    foreach my $directory (keys %{$directory_tree_href}) {
        # mirror directory structure only if local dir contains any files
        if (@{$directory_tree_href->{$directory}}) {
            $ftp->mkdir($directory);
            $ftp->cwd($directory);
            foreach my $file (@{$directory_tree_href->{$directory}}) {
                # upload local $images_directory/$directory/$file via ftp
                $ftp->put("$config_href->{'images_directory'}/$directory/$file");
            }
            $ftp->cdup();
        }
    }
    print "allsender.pl: successfully uploaded recursively all local images\n";
}

=head2
    Deletes everything below $images_directory
=cut
sub remove_all_directories {
    my %args = @_;
    my $directory_tree_href = $args{'directory_tree_href'};
    my $config_href         = $args{'config_href'};
    
    if (not %{$directory_tree_href}) {
        print "allsender.pl: no local files to delete\n";
        return;
    }
    
    foreach my $directory (keys %{$directory_tree_href}) {
        rmtree("$config_href->{'images_directory'}/$directory");
    }
    
    print "allsender.pl: successfully deleted recursively all local images\n";
}

=head2
    Reads from config file.
    Sets global variables for ftp.
=cut
sub get_config {
    my ($ftpserver, $username, $password, $images_directory);
    open(my $config, "ftplc.cfg") or die $!;
    while(<$config>) {
        ($ftpserver)         = ($_ =~ m/FTPSERVER='(.+)'/) if $_ =~ m/FTPSERVER/;
        ($username)          = ($_ =~ m/USERNAME='(.+)'/)  if $_ =~ m/USERNAME/;
        ($password)          = ($_ =~ m/PASSWORD='(.+)'/)  if $_ =~ m/PASSWORD/;
        ($images_directory)  = ($_ =~ m/IMAGES_DIRECTORY=(.+)/)  if $_ =~ m/IMAGES_DIRECTORY/;
        print "test: $_\n";
    }
    close($config);
    
    return({ftpserver        => $ftpserver,
            username         => $username,
            password         => $password,
            images_directory => $images_directory})
}

sub get_ftp_connection {
    my %args        = @_;
    my $config_href = $args{'config_href'};
    
    my $ftp = Net::FTP->new($config_href->{'ftpserver'}) or die $!;
    $ftp->login($config_href->{'username'}, $config_href->{'password'});
    $ftp->binary;
    
    return $ftp;
}

sub close_ftp_connection {
    my %args = @_;
    my $ftp  = $args{'ftp'};

    $ftp->quit;
}

sub main {

    my $config_href         = &get_config();
    my $ftp                 = &get_ftp_connection(config_href => $config_href);
    my $directory_tree_href = &get_directory_structure(config_href => $config_href);
    &upload_all_images(directory_tree_href      => $directory_tree_href,
                       ftp                      => $ftp);
    &remove_all_directories(directory_tree_href => $directory_tree_href);
    &close_ftp_connection(ftp                   => $ftp);
    
}

&main();
