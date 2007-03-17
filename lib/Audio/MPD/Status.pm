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

package Audio::MPD::Status;

use warnings;
use strict;

use base qw[ Class::Accessor::Fast ];
__PACKAGE__->mk_accessors
    ( qw[ audio bitrate error playlist playlistlength random
          repeat song songid state time volume xfade ] );

#our ($VERSION) = '$Rev: 5645 $' =~ /(\d+)/;


#--
# Constructor

#
# my $status = Audio::MPD::Status->new( @output )
#
# The constructor for the class Audio::MPD::Status. @output is what MPD
# server returns to the status command.
#
sub new {
    my $class = shift;
    my (@output) = @_;

    my $self = {
        map { /^([^:]+):\s+(.+)$/ ? ($1 => $2) : () }
        @output
    };
    bless $self, $class;
    return $self;
}

1;

__END__

=pod

=head1 NAME

Audio::MPD::Status - class representing MPD status


=head1 SYNOPSIS

    my $status = $mpd->status;


=head1 DESCRIPTION

The MPD server maintains some information on its current state. Those
information can be queried with the C<status()> method of C<Audio::MPD>.
This method returns an C<Audio::MPD::Status> object, containing all
relevant information.

Note that an C<Audio::MPD::Status> object does B<not> update itself regularly,
and thus should be used immediately.


=head1 METHODS

=head2 Constructor

=over 4

=item new( @output )

The C<new()> method is the constructor for the C<Audio::MPD::Status> class.
It is called internally by the C<status()> method of C<Audio::MPD>, with the
result of the C<status> command sent to MPD server.

Note: one should B<never> ever instantiate an C<Audio::MPD::Status> object
directly - use the C<status()> method of C<Audio::MPD>.

=back


=head2 Accessors

Once created, one can access to the following members of the object:

=over 4

=item audio()

A string with the sample rate of the song currently playing, number of bits
of the output and number of channels (2 for stereo) - separated by a colon.

=item bitrate()

The instantaneous bitrate in kbps.

=item error()

May appear in special error cases, such as when disabling output.


=item playlist()

The playlist version number, that changes every time the playlist is updated.

=item playlistlength()

The number of songs in the playlist.

=item random()

Whether the playlist is read randomly or not.

=item repeat()

Whether the song is repeated or not.

=item song()

The offset of the song currently played in the playlist.

=item songid()

The song id (MPD id) of the song currently played.

=item state()

The state of MPD server. Either C<play>, C<stop> or C<pause>.

=item time()

A string with the time played so far and the total time of the current song,
separated by a colon.

=item volume()

The current MPD volume - an integer between 0 and 100.

=item xfade()

The crossfade in seconds.

=back

Please note that those accessors are read-only: changing a value will B<not>
change the current settings of MPD server. Use C<Audio::MPD> methods to
alter the settings.


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
