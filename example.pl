#!/usr/bin/perl -w
use strict;

die("MPD.pm not found!\n") unless -f "MPD.pm";
require("MPD.pm");

my $x = MPD->new();
$x->connect();

print "Example: Shows MPD.pm used to write mpc-like output\n\n";

print($x->gettitle,"\n");
print("[".$x->{state}."] #".$x->{song}."/".$x->{playlistlength}."   ".$x->gettimeformat."\n");
print("volume: ".$x->{volume}."%  repeat: ".$x->{repeat}."   random: ".$x->{random}."\n");

print "\n\nExample: Shows list of all files, directories and playlists in a specific directory.\n";
print "NB! This is to show how listallinfo() / lsinfo() is used with nextinfo(). It should only be used this way!\n\n";

$x->listallinfo('Classical');
my %foo;
while(%foo = $x->nextinfo)
{
    print $foo{'file'} || $foo{'directory'} || $foo{'playlist'},"\n";
}
