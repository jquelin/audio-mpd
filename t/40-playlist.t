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
use FindBin qw[ $Bin ];
use Test::More;

# are we able to test module?
eval 'use Audio::MPD::Test';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;


plan tests => 24;
my $mpd = Audio::MPD->new;
my ($nb, @items);


#
# testing collection accessor.
my $pl = $mpd->playlist;
isa_ok( $pl, 'Audio::MPD::Playlist',
        'playlist return an Audio::MPD::Playlist object' );


#
# testing playlist retrieval.
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
@items = $pl->as_items;
isa_ok( $_, 'Audio::MPD::Item::Song',
        'as_items() returns Audio::MPD::Item::Song objects' ) for @items;
is( $items[0]->title, 'ok-title', 'first song reported first' );


#
# testing playlist changes retrieval.
@items = $pl->items_changed_since(0);
isa_ok( $_, 'Audio::MPD::Item::Song',
        'items_changed_since() returns Audio::MPD::Item::Song objects' )
    for @items;
is( $items[0]->title, 'ok-title', 'first song reported first' );


#
# testing song insertion.
$pl->clear;
$nb = $mpd->status->playlistlength;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
is( $mpd->status->playlistlength, $nb+3, 'add() songs' );


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
is( $mpd->status->playlistlength, $nb-2, 'delete() songs' );

$nb = $mpd->status->playlistlength;
$pl->deleteid( $mpd->status->songid );
is( $mpd->status->playlistlength, $nb-1, 'deleteid() songs' );



#
# testing playlist clearing
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
$nb = $mpd->status->playlistlength;
$pl->clear;
is(   $mpd->status->playlistlength, 0,   'clear() leaves 0 songs' );
isnt( $mpd->status->playlistlength, $nb, 'clear() changes playlist length' );


#
# testing cropping.
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
$mpd->play(1); # to set song
$mpd->stop;
$pl->crop;
is( $mpd->status->playlistlength, 1, 'crop() leaves only one song' );


#
# testing shuffle.
$pl->clear;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
my $vers = $mpd->status->playlist;
$pl->shuffle;
is( $mpd->status->playlist, $vers+1, 'shuffle() changes playlist version' );


#
# testing swap.
$pl->clear;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
$pl->swap(0,2);
is( ($pl->as_items)[2]->title, 'ok-title', 'swap() changes songs' );


#
# testing swapid.
$pl->clear;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
@items = $pl->as_items;
$pl->swapid($items[0]->id,$items[2]->id);
is( ($pl->as_items)[2]->title, 'ok-title', 'swapid() changes songs' );


#
# testing move.
$pl->clear;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
$pl->move(0,2);
is( ($pl->as_items)[2]->title, 'ok-title', 'move() changes song' );


#
# testing moveid.
$pl->clear;
$pl->add( 'title.ogg' );
$pl->add( 'dir1/title-artist-album.ogg' );
$pl->add( 'dir1/title-artist.ogg' );
@items = $pl->as_items;
$pl->moveid($items[0]->id,2);
is( ($pl->as_items)[2]->title, 'ok-title', 'moveid() changes song' );


#
# testing load.
$pl->clear;
$pl->load( 'test' );
@items = $pl->as_items;
is( scalar @items, 1, 'load() adds songs' );
is( $items[0]->title, 'ok-title', 'load() adds the correct songs' );


#
# testing save.
$pl->clear;
$pl->save( 'test-jq' );
ok( -f "$Bin/mpd-test/playlists/test-jq.m3u", 'save() creates a playlist' );


#
# testing rm.
$pl->rm( 'test-jq' );
ok( ! -f "$Bin/mpd-test/playlists/test-jq.m3u", 'rm() removes a playlist' );



exit;
