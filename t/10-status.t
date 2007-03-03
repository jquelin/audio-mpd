#!perl
#
# This file is part of Audio::MPD.
# Copyright (c) 2007 Jerome Quelin <jquelin@cpan.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#

use strict;
use warnings;

use Audio::MPD::Status;
use Test::More tests => 13;


# note that the first line does not match 'key: value' pattern
# and has been added for the sake of testing. :-)
my $output = '
volume: 66
repeat: 1
random: 0
playlist: 24
playlistlength: 21
xfade: 14
state: play
song: 10
songid: 11
time: 45:214
bitrate: 127
audio: 44100:16:2
';
my @output = split /\n/, $output;

my $s = Audio::MPD::Status->new( @output );
isa_ok( $s, 'Audio::MPD::Status', 'object creation' );
is( $s->volume,         66,           'accessor: volume' );
is( $s->repeat,         1,            'accessor: repeat' );
is( $s->random,         0,            'accessor: random' );
is( $s->playlist,       24,           'accessor: playlist' );
is( $s->playlistlength, 21,           'accessor: playlistlength' );
is( $s->xfade,          14,           'accessor: xfade' );
is( $s->state,          'play',       'accessor: state' );
is( $s->song,           10,           'accessor: song' );
is( $s->songid,         11,           'accessor: songid' );
is( $s->time,           '45:214',     'accessor: time' );
is( $s->bitrate,        127,          'accessor: bitrate' );
is( $s->audio,          '44100:16:2', 'accessor: audio' );
