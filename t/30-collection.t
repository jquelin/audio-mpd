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

plan tests => 73;
my $mpd = Audio::MPD->new;
my @list;


#
# testing collection accessor.
my $coll = $mpd->collection;
isa_ok( $coll, 'Audio::MPD::Collection',
        'collection return an Audio::MPD::Collection object' );


#
# testing all_items.
@list = $coll->all_items;
is( scalar @list, 6, 'all_items return all 6 items' );
isa_ok( $_, 'Audio::MPD::Item', 'all_items return AMI objects' )
    for @list;
@list = $coll->all_items( 'dir1' );
is( scalar @list, 3, 'all_items can be restricted to a subdir' );
is( $list[0]->directory, 'dir1', 'all_items return a subdir first' );
is( $list[1]->artist, 'dir1-artist', 'all_items can be restricted to a subdir' );


#
# testing all_items_simple.
@list = $coll->all_items_simple;
is( scalar @list, 6, 'all_items_simple return all 6 items' );
isa_ok( $_, 'Audio::MPD::Item', 'all_items_simple return AMI objects' )
    for @list;
@list = $coll->all_items_simple( 'dir1' );
is( scalar @list, 3, 'all_items_simple can be restricted to a subdir' );
is( $list[0]->directory, 'dir1', 'all_items_simple return a subdir first' );
is( $list[1]->artist, undef, 'all_items_simple does not return full tags' );


#
# testing items_in_dir.
@list = $coll->items_in_dir;
is( scalar @list, 3, 'items_in_dir defaults to root' );
isa_ok( $_, 'Audio::MPD::Item', 'items_in_dir return AMI objects' ) for @list;
@list = $coll->items_in_dir( 'dir1' );
is( scalar @list, 2, 'items_in_dir can take a param' );


#
# testing all_songs.
@list = $coll->all_songs;
is( scalar @list, 4, 'all_songs return all 4 songs' );
isa_ok( $_, 'Audio::MPD::Item::Song', 'all_items return AMIS objects' ) for @list;
@list = $coll->all_songs( 'dir1' );
is( scalar @list, 2, 'all_songs can be restricted to a subdir' );
is( $list[0]->artist, 'dir1-artist', 'all_songs can be restricted to a subdir' );


#
# testing all_albums.
@list = $coll->all_albums;
is( scalar @list, 1, 'all_albums return the albums' );
is( $list[0], 'our album', 'all_albums return strings' );


#
# testing all_artists.
@list = $coll->all_artists;
is( scalar @list, 1, 'all_artists return the artists' );
is( $list[0], 'dir1-artist', 'all_artists return strings' );


#
# testing all_titles.
@list = $coll->all_titles;
is( scalar @list, 3, 'all_titles return the titles' );
like( $list[0], qr/-title$/, 'all_titles return strings' );


#
# testing all_pathes.
@list = $coll->all_pathes;
is( scalar @list, 4, 'all_pathes return the pathes' );
like( $list[0], qr/\.ogg$/, 'all_pathes return strings' );


#
# testing song.
my $path = 'dir1/title-artist-album.ogg';
my $song = $coll->song($path);
isa_ok( $song, 'Audio::MPD::Item::Song', 'song return an AMI::Song object' );
is( $song->file, $path, 'song return the correct song' );
is( $song->title, 'foo-title', 'song return a full AMI::Song' );


#
# testing songs_with_filename_partial.
@list = $coll->songs_with_filename_partial('album');
isa_ok( $_, 'Audio::MPD::Item::Song', 'songs_with_filename_partial return AMI::Song objects' )
    for @list;
like( $list[0]->file, qr/album/, 'songs_with_filename_partial return the correct song' );


#
# testing albums_by_artist.
@list = $coll->albums_by_artist( 'dir1-artist' );
is( scalar @list, 1, 'albums_by_artist return the album' );
is( $list[0], 'our album', 'albums_by_artist return plain strings' );


#
# testing songs_by_artist.
@list = $coll->songs_by_artist( 'dir1-artist' );
is( scalar @list, 2, 'songs_by_artist return all the songs found' );
isa_ok( $_, 'Audio::MPD::Item::Song', 'songs_by_artist return AMI::Songs' ) for @list;
is( $list[0]->artist, 'dir1-artist', 'songs_by_artist return correct objects' );


#
# testing songs_by_artist_partial.
@list = $coll->songs_by_artist_partial( 'artist' );
is( scalar @list, 2, 'songs_by_artist_partial return all the songs found' );
isa_ok( $_, 'Audio::MPD::Item::Song', 'songs_by_artist_partial return AMI::Songs' ) for @list;
like( $list[0]->artist, qr/artist/, 'songs_by_artist_partial return correct objects' );


#
# testing songs_from_album.
@list = $coll->songs_from_album( 'our album' );
is( scalar @list, 2, 'songs_from_album return all the songs found' );
isa_ok( $_, 'Audio::MPD::Item::Song', 'songs_from_album return AMI::Songs' ) for @list;
is( $list[0]->album, 'our album', 'songs_from_album_partial return correct objects' );


#
# testing songs_from_album_partial.
@list = $coll->songs_from_album_partial( 'album' );
is( scalar @list, 2, 'songs_from_album_partial return all the songs found' );
isa_ok( $_, 'Audio::MPD::Item::Song', 'songs_from_album_partial return AMI::Songs' ) for @list;
like( $list[0]->album, qr/album/, 'songs_from_album_partial return correct objects' );


#
# testing songs_with_title.
@list = $coll->songs_with_title( 'ok-title' );
is( scalar @list, 1, 'songs_with_title return all the songs found' );
isa_ok( $_, 'Audio::MPD::Item::Song', 'songs_with_title return AMI::Songs' ) for @list;
is( $list[0]->title, 'ok-title', 'songs_with_title return correct objects' );


#
# testing songs_with_title_partial.
@list = $coll->songs_with_title_partial( 'title' );
is( scalar @list, 3, 'songs_with_title_partial return all the songs found' );
isa_ok( $_, 'Audio::MPD::Item::Song', 'songs_with_title_partial return AMI::Songs' ) for @list;
like( $list[0]->title, qr/title/, 'songs_with_title_partial return correct objects' );


exit;
