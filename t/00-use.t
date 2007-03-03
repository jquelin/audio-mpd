#!perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { use_ok( 'Audio::MPD' ); }
diag( "Testing Audio::MPD $Audio::MPD::VERSION, Perl $], $^X" );
