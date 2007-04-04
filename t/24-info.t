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

use Audio::MPD;
use Test::More;

# are we able to test module?
eval 'use Audio::MPD::Test';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 19;
my $mpd = Audio::MPD->new;
my $song;

#
# testing stats
$mpd->updatedb;
$mpd->playlist->add( 'title.ogg' );
$mpd->playlist->add( 'dir1/title-artist-album.ogg' );
$mpd->playlist->add( 'dir1/title-artist.ogg' );
my $stats = $mpd->stats;
is( $stats->{artists},      1, 'one artist in the database' );
is( $stats->{albums},       1, 'one album in the database' );
is( $stats->{songs},        4, '4 songs in the database' );
is( $stats->{playtime},     0, 'already played 0 seconds' );
is( $stats->{db_playtime},  8, '8 seconds worth of music in the db' );
isnt( $stats->{uptime}, undef, 'uptime is defined' );
isnt( $stats->{db_update},  0, 'database has been updated' );


#
# testing status.
$mpd->play;
$mpd->pause;
my $status = $mpd->status;
isa_ok( $status, 'Audio::MPD::Status', 'status return an Audio::MPD::Status object' );


#
# testing current song.
$song = $mpd->current;
isa_ok( $song, 'Audio::MPD::Item::Song', 'current return an Audio::MPD::Item::Song object' );


#
# testing playlist changes retrieval.
my @list = $mpd->pl_changes(0);
isa_ok( $_, 'Audio::MPD::Item::Song', 'pl_changes() returns Audio::MPD::Item::Song objects' )
    for @list;
is( $list[0]->title, 'ok-title', 'first song reported first' );


#
# testing song.
$song = $mpd->song(1);
isa_ok( $song, 'Audio::MPD::Item::Song', 'song() returns an Audio::MPD::Item::Song object' );
is( $song->file, 'dir1/title-artist-album.ogg', 'song() returns the wanted song' );
$song = $mpd->song; # default to current song
is( $song->file, 'title.ogg', 'song() defaults to current song' );


#
# testing songid.
$song = $mpd->songid(1);
isa_ok( $song, 'Audio::MPD::Item::Song', 'songid() returns an Audio::MPD::Item::Song object' );
is( $song->file, 'dir1/title-artist-album.ogg', 'songid() returns the wanted song' );
$song = $mpd->songid; # default to current song
is( $song->file, 'title.ogg', 'songid() defaults to current song' );


exit;
