#!/usr/bin/perl -w
use strict;
use Data::Dumper;

die("MPD.pm not found!\n") unless -f "MPD.pm";
require("MPD.pm");

#my $x = MPD->new('localhost',2100); # Do this for specifing server and/or port.
my $x = MPD->new();
$x->connect();
print "Example: Shows MPD.pm used to write mpc-like output\n\n";
print($x->gettitle,"\n");
print("[".$x->{state}."] #".($x->{song} || 'n/a')."/".$x->{playlistlength}."   ".$x->gettimeformat."\n");
print("volume: ".$x->{volume}."%  repeat: ".$x->{repeat}."   random: ".$x->{random}."\n");

print "\n\nExample: Shows list of all files, directories and playlists in a specific directory.\n";
print "NB! This is to show how listallinfo() / lsinfo() is used with nextinfo(). It should only be used this way!\n\n";

$x->listallinfo('Alternative');
my %foo;
while(%foo = $x->nextinfo)
{
    print $foo{'file'} || $foo{'directory'} || $foo{'playlist'},"\n"; # Don't ever, ever, ever, ever stop the loop!
}

print "\n\nExample: Shows how to get information from the playlist. \@playlist is a reference, so don't change it :)\n\n";
my $plist = $x->playlist;
my @playlist = @$plist;
print "Song 42 filename: ".$playlist[42]{'file'}."\n";
print "Song 13 time: ".$playlist[13]{'Time'}."\n";
