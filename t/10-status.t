#!perl
#
# This file is part of Audio::MPD
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Audio::MPD::Status;
use Test::More tests => 14;


my %kv = (
    volume         => 66,
    repeat         => 1,
    random         => 0,
    playlist       => 24,
    playlistlength => 21,
    xfade          => 14,
    state          => 'play',
    song           => 10,
    songid         => 11,
    time           => '45:214',
    bitrate        => 127,
    audio          => '44100:16:2',
    error          => 'problems opening audio device',
);

my $s = Audio::MPD::Status->new( %kv );
isa_ok( $s, 'Audio::MPD::Status', 'object creation' );
is( $s->volume,         66,                              'accessor: volume' );
is( $s->repeat,         1,                               'accessor: repeat' );
is( $s->random,         0,                               'accessor: random' );
is( $s->playlist,       24,                              'accessor: playlist' );
is( $s->playlistlength, 21,                              'accessor: playlistlength' );
is( $s->xfade,          14,                              'accessor: xfade' );
is( $s->state,          'play',                          'accessor: state' );
is( $s->song,           10,                              'accessor: song' );
is( $s->songid,         11,                              'accessor: songid' );
isa_ok( $s->time,       'Audio::MPD::Time',              'accessor: time' );
is( $s->bitrate,        127,                             'accessor: bitrate' );
is( $s->audio,          '44100:16:2',                    'accessor: audio' );
is( $s->error,          'problems opening audio device', 'accessor: error' );
