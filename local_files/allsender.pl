#!/usr/bin/perl

=head1
    Ich hätte das ganze von Anfang an in Perl schreiben sollen.
=cut

use warnings;
use strict;

use Data::Dumper;
use Cwd qw(abs_path cwd);
use File::Basename;
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

    foreach my $curdir (@ARGV) {
        next if $curdir !~ m/\dT\d/;
        next if not -d "$config_href->{'images_directory'}/$curdir";
        my $dir_handle;
        opendir($dir_handle, "$config_href->{'images_directory'}/$curdir");
        $directory_tree{$curdir} = [grep(/jpg/,readdir($dir_handle))];
        closedir($dir_handle);
    }
    return \%directory_tree;
}

=head2
    Uploads the directories recursively.
=cut
sub upload_and_remove_all_images {
    my %args                = @_;
    my $directory_tree_href = $args{'directory_tree_href'};
    my $ftp_sref            = $args{'ftp_sref'};
    my $config_href         = $args{'config_href'};
    
    if (not %{$directory_tree_href}) {
        print "        allsender.pl: no local files to upload\n";
        return;
    }
    
    foreach my $directory (keys %{$directory_tree_href}) {
        print "   allsender.pl::upload_all_images(): directory:$directory \n";
        # mirror directory structure only if local dir contains any files
        if (@{$directory_tree_href->{$directory}}) {
            chdir("$config_href->{'images_directory'}/$directory");
            $$ftp_sref->mkdir($directory);
            $$ftp_sref->cwd($directory);
            foreach my $file (@{$directory_tree_href->{$directory}}) {
            print "   allsender.pl::upload_all_images(): file: $file\n";
                # upload local $images_directory/$directory/$file via ftp
#                $$ftp_sref->put($file) || warn "didn't work to put $file: $!";
                if ($$ftp_sref->put($file)) {
                    print "        allsender.pl: successfully uploaded '$file'\n";
                    if (unlink("$config_href->{'images_directory'}/$directory/$file")) {
                        print "        allsender.pl: successfully deleted '$file'\n";
                    }
                    else {
                        print "        allsender.pl: unable to delete '$file'\n";
                    }
                }
                else {
                    print "        allsender.pl: unable to put '$file': $!";
                }
            }
            $$ftp_sref->cdup();
            chdir("..");
                if (rmtree("$config_href->{'images_directory'}/$directory")) {
                print "        allsender.pl: successfully deleted directory '$directory'\n";
                print "\n";
            }
            else {
                print "        allsender.pl: unable to delete directory '$directory'\n";
            }
        }
    }
}

=head2
    Deletes everything below $images_directory
=cut
sub remove_all_directories {
    my %args = @_;
    my $directory_tree_href = $args{'directory_tree_href'};
    my $config_href         = $args{'config_href'};
    
    if (not %{$directory_tree_href}) {
        print "        allsender.pl: no local files to delete\n";
        return;
    }
    
    foreach my $directory (keys %{$directory_tree_href}) {
        rmtree("$config_href->{'images_directory'}/$directory");
    }
    
    print "        allsender.pl: successfully deleted recursively all local images\n";
}

=head2
    Reads from config file.
    Sets global variables for ftp.
=cut
sub get_config {
    my ($ftpserver, $username, $password, $images_directory);
    my $script_directory = dirname(abs_path($0));
    
    open(my $config, "$script_directory/ftplc.cfg") or die $!;
    while(<$config>) {
        ($ftpserver)         = ($_ =~ m/FTPSERVER='(.+)'/) if $_ =~ m/FTPSERVER/;
        ($username)          = ($_ =~ m/USERNAME='(.+)'/)  if $_ =~ m/USERNAME/;
        ($password)          = ($_ =~ m/PASSWORD='(.+)'/)  if $_ =~ m/PASSWORD/;
        ($images_directory)  = ($_ =~ m/IMAGES_DIRECTORY=(.+)/)  if $_ =~ m/IMAGES_DIRECTORY/;
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
    
    return \$ftp;
}

sub close_ftp_connection {
    my %args = @_;
    my $ftp_sref  = $args{'ftp_sref'};

    $$ftp_sref->quit;
}

sub main {
    print "\n   allsender.pl BEGIN\n\n";
    my $config_href         = &get_config();
    my $ftp_sref            = &get_ftp_connection(config_href => $config_href,);
    my $directory_tree_href = &get_directory_structure(config_href => $config_href,);
    
    &upload_and_remove_all_images(directory_tree_href      => $directory_tree_href,
                                  ftp_sref                 => $ftp_sref,
                                  config_href              => $config_href,);
    
    &close_ftp_connection(ftp_sref                         => $ftp_sref,);
    
    print "\n   allsender.pl END\n\n";
}

&main();
