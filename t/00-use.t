#!perl
#
# This file is part of Audio::MPD
# Copyright (c) 2007-2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok( 'Audio::MPD' ); }
diag( "Testing Audio::MPD $Audio::MPD::VERSION, Perl $], $^X" );

use_ok( 'Audio::MPD::Collection' );
use_ok( 'Audio::MPD::Playlist' );
