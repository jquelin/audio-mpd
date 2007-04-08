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

package Audio::MPD::Stats;

use warnings;
use strict;

use base qw[ Class::Accessor::Fast ];
__PACKAGE__->mk_accessors
    ( qw[ artists albums songs uptime playtime db_playtime db_update ] );

#our ($VERSION) = '$Rev$' =~ /(\d+)/;


#--
# Constructor

#
# my $status = Audio::MPD::Stats->new( %kv )
#
# The constructor for the class Audio::MPD::Stats. %kv is a cooked output
# of what MPD server returns to the status command.
#
sub new {
    my $class = shift;
    my %kv = @_;
    bless \%kv, $class;
    return \%kv;
}

1;

__END__

=pod

=head1 NAME

Audio::MPD::Stats - class representing MPD stats


=head1 SYNOPSIS

    my $status = $mpd->stats;
    print $stats->artists;


=head1 DESCRIPTION

The MPD server maintains some general information. Those information can be
queried with the C<stats()> method of C<Audio::MPD>. This method returns an
C<Audio::MPD::Stats> object, containing all relevant information.

Note that an C<Audio::MPD::Stats> object does B<not> update itself regularly,
and thus should be used immediately.


=head1 METHODS

=head2 Constructor

=over 4

=item new( %kv )

The C<new()> method is the constructor for the C<Audio::MPD::Status> class.
It is called internally by the C<stats()> method of C<Audio::MPD>, with the
result of the C<stats> command sent to MPD server.

Note: one should B<never> ever instantiate an C<Audio::MPD::Stats> object
directly - use the C<stats()> method of C<Audio::MPD>.

=back


=head2 Accessors

Once created, one can access to the following members of the object:

=over 4

=item $stats->artists()

Number of artists in the music database.


=item $stats->albums()

Number of albums in the music database.


=item $stats->songs()

Number of songs in the music database.


=item $stats->uptime()

Daemon uptime (time since last startup) in seconds.


=item $stats->playtime()

Time length of music played.


=item $stats->db_playtime()

Sum of all song times in the music database.


=item $stats->db_update()

Last database update in UNIX time.


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
