#!/usr/bin/perl -w
use strict;
use Data::Dumper;

die("MPD.pm not found!\n") unless -f "MPD.pm";
require("MPD.pm");

my $x = MPD->new();
$x->connect();

print($x->gettitle,"\n");
print("[".$x->{state}."] #".$x->{song}."/".$x->{playlistlength}."   ".$x->gettimeformat."\n");
print("volume: ".$x->{volume}."%  repeat: ".$x->{repeat}."   random: ".$x->{random}."\n");

