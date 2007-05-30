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

use Audio::MPD::Stats;
use Test::More tests => 8;


my %kv = (
    artists     => 3,
    albums      => 2,
    songs       => 4,
    uptime      => 10002,
    playtime    => 5,
    db_playtime => 8,
    db_update   => 1175631570,
);

my $s = Audio::MPD::Stats->new( %kv );
isa_ok( $s, 'Audio::MPD::Stats', 'object creation' );
is( $s->artists,     3,          'accessor: artists' );
is( $s->albums,      2,          'accessor: albums' );
is( $s->songs,       4,          'accessor: songs' );
is( $s->uptime,      10002,      'accessor: uptime' );
is( $s->playtime,    5,          'accessor: playtime' );
is( $s->db_playtime, 8,          'accessor: db_playtime' );
is( $s->db_update,   1175631570, 'accessor: db_update' );
