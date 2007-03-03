#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#

use strict;
use warnings;

use Audio::MPD;
use Test::More;

# are we able to test module?
eval 'use Audio::MPD::Test';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 10;
my $mpd;

#
# testing constructor defaults.
$mpd = Audio::MPD->new;
is( $mpd->_host,     'localhost', 'host defaults to localhost' );
is( $mpd->_port,     6600,        'port defaults to 6600' );
is( $mpd->_password, '',          'password default to empty string' );
isa_ok( $mpd, 'Audio::MPD', 'object creation' );


#
# changing fake mpd config to test constructor.
my $port = 16600;
stop_test_mpd();
customize_test_mpd_configuration($port);
start_test_mpd();


#
# testing constructor params.
$mpd = Audio::MPD->new('127.0.0.1', $port, 'foobar' );
is( $mpd->_host,     '127.0.0.1', 'host set to param' );
is( $mpd->_port,     $port,       'port set to param' );
is( $mpd->_password, 'foobar',    'password set to param' );

#
# testing constructor environment defaults...
$ENV{MPD_HOST}     = '127.0.0.1';
$ENV{MPD_PORT}     = $port;
$ENV{MPD_PASSWORD} = 'foobar';
$mpd = Audio::MPD->new;
is( $mpd->_host,     $ENV{MPD_HOST},     'host default to $ENV{MPD_HOST}' );
is( $mpd->_port,     $ENV{MPD_PORT},     'port default to $ENV{MPD_PORT}' );
is( $mpd->_password, $ENV{MPD_PASSWORD}, 'port default to $ENV{MPD_PASSWORD}' );

delete $ENV{MPD_HOST};
delete $ENV{MPD_PORT};
delete $ENV{MPD_PASSWORD};

exit;
