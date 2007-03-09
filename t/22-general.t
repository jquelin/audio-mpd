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

plan tests => 8;
my $mpd = Audio::MPD->new;


#
# testing mpd version.
SKIP: {
    my $output = qx[mpd --version 2>/dev/null];
    skip 'need mpd installed', 1 unless $output =~ /^mpd .* ([\d.]+)\n/;
    is( $mpd->version, $1, 'mpd version grabbed during connection' );
}


#
# testing kill.
$mpd->ping;
$mpd->kill;
eval { $mpd->ping };
like( $@, qr/^Could not create socket:/, 'kill shuts mpd down' );
start_test_mpd();


#
# testing password changing.
eval { $mpd->password('b0rken') };
like( $@, qr/\{password\} incorrect password/, 'changing password' );
eval { $mpd->password() }; # default to empty string.
is( $@, '', 'no password = empty password' );


#
# testing database updating.
# uh - what are we supposed to test? that there was no error?
eval { $mpd->updatedb };
is( $@, '', 'updating whole collection' );
sleep 1; # let the first update finish.
eval { $mpd->updatedb('dir1') };
is( $@, '', 'updating part of collection' );


#
# testing urlhandlers.
my @handlers = $mpd->urlhandlers;
is( scalar @handlers,     1, 'only one url handler supported' );
is( $handlers[0], 'http://', 'only http is supported by now' );

exit;
