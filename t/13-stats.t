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
