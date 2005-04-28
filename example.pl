#!/usr/bin/perl -w
use strict;
use Data::Dumper;

die("MPD.pm not found!\n") unless -f "MPD.pm";
require("MPD.pm");

#my $x = MPD->new('localhost',2100); # Do this for specifing server and/or port.
my $x = MPD->new();
print "Example: Shows MPD.pm used to write mpc-like output\n\n";
print($x->get_title,"\n");
print("[".$x->{state}."] #".($x->{song} || 'n/a')."/".$x->{playlistlength}."   ".$x->get_time_format."\n");
print("volume: ".$x->{volume}."%  repeat: ".$x->{repeat}."   random: ".$x->{random}."\n");

print "\n\nExample: Shows list of all files, directories and playlists in a specific directory.\n";



my @array = $x->listallinfo('Misc');
foreach(@array)
{
	print $_->{'file'} || $_->{'directory'} || $_->{'playlist'},"\n";
}



print "\n\nExample: Shows how to get information from the playlist. \@playlist is a reference, so don't change it :)\n\n";
my $playlist = $x->playlist;
print "Song 42 filename: ".$playlist->[42]{'file'}."\n";
print "Song 13 time: ".$playlist->[13]{'Time'}." seconds\n";
