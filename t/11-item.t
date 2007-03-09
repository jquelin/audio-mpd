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

use Audio::MPD::Item;
use Test::More tests => 18;

my ($i, $output, @output, %params);

#
# testing audio::mpd::item::song
$output = 'file: some/random/path/to/a/song.ogg
Time: 234
Artist: Foo Bar
Album: Frobnizer
Track: 26
Title: Blah!
Pos: 10
Id: 14
';
@output = split /\n/, $output;
%params = map { /^([^:]+):\s+(.*)$/ ? ($1=>$2) : () } @output;
$i = Audio::MPD::Item->new( %params );
isa_ok( $i, 'Audio::MPD::Item::Song', 'song creation' );
is( $i->file,   'some/random/path/to/a/song.ogg',  'accessor: file' );
is( $i->time,   234,                               'accessor: time' );
is( $i->artist, 'Foo Bar',                         'accessor: artist' );
is( $i->album,  'Frobnizer',                       'accessor: album' );
is( $i->track,  26,                                'accessor: track' );
is( $i->title,  'Blah!',                           'accessor: title' );
is( $i->pos,    10,                                'accessor: pos' );
is( $i->id,     14,                                'accessor: id' );
isa_ok( $i, 'Audio::MPD::Item', 'song inherits from item' );


#
# testing as_string from audio::mpd::item::song.
is( $i->as_string, 'Frobnizer = 26 = Foo Bar = Blah!', 'as_string() with all tags' );
$i->track(undef);
is( $i->as_string, 'Foo Bar = Blah!', 'as_string() without track' );
$i->track(26); $i->album(undef);
is( $i->as_string, 'Foo Bar = Blah!', 'as_string() without album' );
$i->artist(undef);
is( $i->as_string, 'Blah!',           'as_string() without artist' );
$i->title(undef);
is( $i->as_string, 'some/random/path/to/a/song.ogg', 'as_string() without title' );


#
# testing audio::mpd::item::directory
$output = "directory: some/random/path\n";
@output = split /\n/, $output;
%params = map { /^([^:]+):\s+(.*)$/ ? ($1=>$2) : () } @output;
$i = Audio::MPD::Item->new( %params );
isa_ok( $i, 'Audio::MPD::Item::Directory', 'directory creation' );
is( $i->directory, 'some/random/path',  'accessor: directory' );
isa_ok( $i, 'Audio::MPD::Item', 'directory inherits from item' );


exit;
