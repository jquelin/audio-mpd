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

plan tests => 10;
my $mpd = Audio::MPD->new;


#
# testing repeat
$mpd->repeat(1);
is( $mpd->status->repeat, 1, 'enabling repeat mode' );
$mpd->repeat(0);
is( $mpd->status->repeat, 0, 'disabling repeat mode' );
$mpd->repeat;
is( $mpd->status->repeat, 1, 'toggling repeat mode to on' );
$mpd->repeat;
is( $mpd->status->repeat, 0, 'toggling repeat mode to off' );


#
# testing random
$mpd->random(1);
is( $mpd->status->random, 1, 'enabling random mode' );
$mpd->random(0);
is( $mpd->status->random, 0, 'disabling random mode' );
$mpd->random;
is( $mpd->status->random, 1, 'toggling random mode to on' );
$mpd->random;
is( $mpd->status->random, 0, 'toggling random mode to off' );


#
# testing fade
$mpd->fade(15);
is( $mpd->status->xfade, 15, 'enabling fading' );
$mpd->fade;
is( $mpd->status->xfade,  0, 'disabling fading by default' );


exit;
