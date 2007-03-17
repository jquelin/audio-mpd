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

package Audio::MPD::Item::Directory;

use strict;
use warnings;

use base qw[ Class::Accessor::Fast Audio::MPD::Item ];
__PACKAGE__->mk_accessors( qw[ directory ] );

#our ($VERSION) = '$Rev: 5645 $' =~ /(\d+)/;

1;

=head1 NAME

Audio::MPD::Item::Directory - a directory object


=head1 SYNOPSIS

    print $item->directory . "\n";


=head1 DESCRIPTION

C<Audio::MPD::Item::Directory> is more a placeholder for a hash ref with one
pre-defined key, namely the directory name.


=head1 PUBLIC METHODS

This module only has a C<new()> constructor, which should only be called by
C<Audio::MPD::Item>'s constructor.

The only other public method is an accessor: directory().


=head1 SEE ALSO

You can find more information on the mpd project on its homepage at
L<http://www.musicpd.org>, or its wiki L<http://mpd.wikia.com>.

Regarding this Perl module, you can report bugs on CPAN via
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Audio-MPD>.

Audio::MPD development takes place on <audio-mpd@googlegroups.com>: feel free
to join us. (use L<http://groups.google.com/group/audio-mpd> to sign in). Our
subversion repository is located at L<https://svn.musicpd.org>.


=head1 AUTHORS

Jerome Quelin <jquelin@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Jerome Quelin <jquelin@cpan.org>


This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut

