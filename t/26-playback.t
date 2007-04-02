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


#
# testing play / playid.
$mpd->clear;
$mpd->add( 'title.ogg' );
$mpd->add( 'dir1/title-artist-album.ogg' );
$mpd->add( 'dir1/title-artist.ogg' );
$mpd->add( 'dir2/album.ogg' );

$mpd->play;
is( $mpd->status->state, 'play', 'play starts playback' );
$mpd->play(2);
is( $mpd->status->song,       2, 'play can start playback at a given song' );

$mpd->play(0);
$mpd->pause;
$mpd->playid;
is( $mpd->status->state, 'play', 'playid starts playback' );
$mpd->playid(1);
is( $mpd->status->songid,     1, 'playid can start playback at a given song' );


#
# testing pause.
$mpd->pause(1);
is( $mpd->status->state, 'pause', 'pause forces playback pause' );
$mpd->pause(0);
is( $mpd->status->state, 'play', 'pause can force playback resume' );
$mpd->pause;
is( $mpd->status->state, 'pause', 'pause toggles to pause' );
$mpd->pause;
is( $mpd->status->state, 'play', 'pause toggles to play' );


#
# testing stop.
$mpd->stop;
is( $mpd->status->state, 'stop', 'stop forces full stop' );


#
# testing prev / next.
$mpd->play(1); $mpd->pause;
$mpd->next;
is( $mpd->status->song, 2, 'next changes track to next one' );
$mpd->prev;
is( $mpd->status->song, 1, 'prev changes track to previous one' );


#
# testing seek / seekid.
$mpd->pause(1);
$mpd->seek( 1, 2 );
is( $mpd->status->song,     2, 'seek can change the current track' );
is( $mpd->status->time, '1:2', 'seek seeks in the song' );
$mpd->seek;
is( $mpd->status->time, '0:2', 'seek defaults to beginning of song' );
$mpd->seek(1);
is( $mpd->status->time, '1:2', 'seek defaults to current song ' );


$mpd->seekid( 1, 1 );
is( $mpd->status->songid,   1, 'seekid can change the current track' );
is( $mpd->status->time, '1:2', 'seekid seeks in the song' );
$mpd->seekid;
is( $mpd->status->time, '0:2', 'seekid defaults to beginning of song' );
$mpd->seekid(1);
is( $mpd->status->time, '1:2', 'seekid defaults to current song' );



exit;
