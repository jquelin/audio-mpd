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

package Audio::MPD::Item;

use strict;
use warnings;
use Carp;
use Audio::MPD::Item::Directory;
use Audio::MPD::Item::Song;


#
# constructor.
#
sub new {
    my ($pkg, %params) = @_;
    croak "new is a class method - can't call it on a ref\n" if ref $pkg;

    # transform keys in lowercase.
    my %lowcase;
    @lowcase{ map { lc } keys %params } = values %params;

    my $item = exists $params{file} ?
        Item::Song->new(\%lowcase) :
        Item::Directory->new(\%lowcase);
    return $item;
}

1;

__END__


=head1 NAME

Audio::MPD::Item - a generic collection item


=head1 SYNOPSIS

    my $item = Audio::MPD::Item->new( %params );


=head1 DESCRIPTION

C<Item> is a class representing a generic item of mpd's collection. It can be
either a song or a directory. Depending on the params given to C<new>, it will
create and return a C<Item::Song> or a C<Item::Directory> object. Currently,
the discrimination is done on the existence of the C<file> key of C<%params>.

Note that the only sub worth it in this class is the constructor.


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
