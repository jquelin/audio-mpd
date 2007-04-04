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

plan tests => 7;
my $mpd = Audio::MPD->new;
my $nb;


#
# testing collection accessor.
my $pl = $mpd->playlist;
isa_ok( $pl, 'Audio::MPD::Playlist',
        'playlist return an Audio::MPD::Playlist object' );


#
# testing song insertion.
$pl->clear;
$nb = $mpd->status->playlistlength;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
is( $mpd->status->playlistlength, $nb+3, 'adding songs' );


#
# testing song removal.
$pl->clear;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
$mpd->play(0); # to set songid
$mpd->stop;
$nb = $mpd->status->playlistlength;
$pl->delete( reverse 1..2 ); # reverse otherwise mpd will get it wrong
is( $mpd->status->playlistlength, $nb-2, 'delete songs' );

$nb = $mpd->status->playlistlength;
$pl->deleteid( $mpd->status->songid );
is( $mpd->status->playlistlength, $nb-1, 'deleteid songs' );



#
# testing playlist clearing
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
$nb = $mpd->status->playlistlength;
$pl->clear;
is(   $mpd->status->playlistlength, 0,   'clearing playlist leaves 0 songs' );
isnt( $mpd->status->playlistlength, $nb, 'clearing songs changes playlist length' );


#
# testing cropping.
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
$mpd->play(1); # to set song
$mpd->stop;
$pl->crop;
is( $mpd->status->playlistlength, 1, 'cropping leaves only one song' );
# FIXME is( $pl->status->get_current


exit;
