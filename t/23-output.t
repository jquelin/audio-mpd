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

plan tests => 5;
my $mpd = Audio::MPD->new;


#
# testing absolute volume.
$mpd->volume(10); # init to sthg that we know
$mpd->volume(42);
is( $mpd->status->volume, 42, 'setting volume' );

#
# testing positive relative volume.
$mpd->volume('+9');
is( $mpd->status->volume, 51, 'increasing volume' );

#
# testing negative relative volume.
$mpd->volume('-4');
is( $mpd->status->volume, 47, 'decreasing volume' );


#
# testing disable_output.
$mpd->add( 'title.ogg' );
$mpd->add( 'dir1/title-artist-album.ogg' );
$mpd->add( 'dir1/title-artist.ogg' );
$mpd->play;
$mpd->output_disable(0);
sleep(1);
like( $mpd->status->error, qr/^problems/, 'disabling output' );

#
# testing enable_output.
$mpd->output_enable(0);
sleep(1);
$mpd->play; $mpd->pause;
is( $mpd->status->error, undef, 'enabling output' );


exit;
