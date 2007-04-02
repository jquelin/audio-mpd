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

plan tests => 17;

my $mpd = Audio::MPD->new;
isa_ok($mpd, 'Audio::MPD');


#
# testing error during socket creation.
$mpd->_port( 16600 );
eval { $mpd->_send_command( "ping\n" ) };
like($@, qr/^Could not create socket/, 'error during socket creation');
$mpd->_port( 6600 );

#
# testing connection to a non-mpd server - here, we'll try to connect
# to a sendmail server.
my $sendmail_running = grep { /:25\s.*LISTEN/ } qx[ netstat -an ];
SKIP: {
    skip 'need some sendmail server running', 1 unless $sendmail_running;
    $mpd->_port( 25 );
    eval { $mpd->ping };
    like($@, qr/^Not a mpd server - welcome string was:/, 'wrong server');
};
$mpd->_port( 6600 );


#
# testing password sending.
$mpd->_password( 'wrong-password' );
eval { $mpd->ping };
like($@, qr/\{password\} incorrect password/, 'wrong password');

$mpd->_password('fulladmin');
eval { $mpd->ping };
is($@, '', 'correct password sent');
$mpd->_password('');


#
# testing command.
eval { $mpd->_send_command( "bad command\n" ); };
like($@, qr/unknown command "bad"/, 'unknown command');

my @output = $mpd->_send_command( "status\n" );
isnt(scalar @output, 0, 'commands return stuff');


#
# testing _cooked_command_as_items
my @items = $mpd->_cooked_command_as_items( "lsinfo\n" );
isa_ok( $_, "Audio::MPD::Item", '_cooked_command_as_items return items' ) for @items;


#
# testing _cooked_command_strip_first_field
my @list = $mpd->_cooked_command_strip_first_field( "stats\n" );
unlike( $_, qr/\D/, '_cooked_command_strip_first_field return only 2nd field' ) for @list;
# stats return numerical data as second field.

exit;
