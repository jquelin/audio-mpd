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

use Test::More tests => 9;

BEGIN { use_ok( 'Audio::MPD' ); }
diag( "Testing Audio::MPD $Audio::MPD::VERSION, Perl $], $^X" );

use_ok( 'Audio::MPD::Status' );
use_ok( 'Audio::MPD::Item::Directory' );
use_ok( 'Audio::MPD::Item::Song' );
use_ok( 'Audio::MPD::Item' );
use_ok( 'Audio::MPD::Collection' );
use_ok( 'Audio::MPD::Playlist' );
use_ok( 'Audio::MPD::Time' );
use_ok( 'Audio::MPD::Stats' );
