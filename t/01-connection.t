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
use Test::More tests => 1;

SKIP: {
    # try to load test framework.
    eval { require Audio::MPD::Test; Audio::MPD::Test->import; };
    skip $@, 1 if $@ =~ s/\n+Compilation failed.*//s;

    my $mpd = Audio::MPD->new;
    isa_ok($mpd, 'Audio::MPD');
}

exit;

