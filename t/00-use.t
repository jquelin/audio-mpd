#!perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok( 'Audio::MPD' ); }
diag( "Testing Audio::MPD $Audio::MPD::VERSION, Perl $], $^X" );

use_ok( 'Audio::MPD::Collection' );
use_ok( 'Audio::MPD::Playlist' );
