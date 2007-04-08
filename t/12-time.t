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

use Audio::MPD::Time;
use Test::More tests => 14;

#
# formatted output
my $time = Audio::MPD::Time->new( '126:225' );
is( $time->sofar,   '2:06', 'sofar() formats time so far' );
is( $time->left,    '1:39', 'left() formats remaining time' );
is( $time->total,   '3:45', 'sofar() formats time so far' );
is( $time->percent, '56.0', 'percent() gives percentage elapsed' );


#
# so far
is( $time->sofar_secs,    6,   'sofar_secs() gives seconds so far' );
is( $time->sofar_mins,    2,   'sofar_mins() gives minutes so far' );
is( $time->seconds_sofar, 126, 'seconds_sofar() gives time so far in secs' );

#
# left details
is( $time->left_secs,    39, 'left_secs() gives seconds left' );
is( $time->left_mins,    1,  'left_mins() gives minutes left' );
is( $time->seconds_left, 99, 'seconds_left() gives time left in secs' );

#
# total details
is( $time->total_secs,    45,  'total_secs() gives seconds total' );
is( $time->total_mins,    3,   'total_mins() gives minutes total' );
is( $time->seconds_total, 225, 'seconds_total() gives time total in secs' );

#
# testing null time
$time = Audio::MPD::Time->new( '126:0' );
is( $time->percent, '0.0', 'percent() defaults to 0' );

exit;
