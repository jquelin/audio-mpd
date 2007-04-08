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

package Audio::MPD::Time;

use warnings;
use strict;

use base qw[ Class::Accessor::Fast ];
__PACKAGE__->mk_accessors
    ( qw[ percent sofar left total
          sofar_secs sofar_mins seconds_sofar
          total_secs total_mins seconds_total
          left_secs  left_mins  seconds_left
        ] );

#our ($VERSION) = '$Rev$' =~ /(\d+)/;


#--
# Constructor

#
# my $status = Audio::MPD::Time->new( $time )
#
# The constructor for the class Audio::MPD::Time. $time is the time value
# (on the "time" line) of what the output MPD server returns to the status
# command.
#
sub new {
    my ($class, $time) = @_;
    my ($seconds_sofar, $seconds_total) = split /:/, $time;
    my $seconds_left = $seconds_total - $seconds_sofar;
    my $percent      = $seconds_total ? 100*$seconds_sofar/$seconds_total : 0;

    # Parse the time so far
    my $sofar_mins = int( $seconds_sofar / 60 );
    my $sofar_secs = $seconds_sofar % 60;
    my $sofar = sprintf "%d:%02d", $sofar_mins, $sofar_secs;

    # Parse the total time
    my $total_mins = int( $seconds_total / 60 );
    my $total_secs = $seconds_total % 60;
    my $total = sprintf "%d:%02d", $total_mins, $total_secs;

    # Parse the time left
    my $left_mins = int( $seconds_left / 60 );
    my $left_secs = $seconds_left % 60;
    my $left = sprintf "%d:%02d", $left_mins, $left_secs;


    # create object
    my $self = {
        # time elapsed in seconds
        seconds_sofar => $seconds_sofar,
        seconds_left  => $seconds_left,
        seconds_total => $seconds_total,

        # cooked values
        sofar      => $sofar,
        left       => $left,
        total      => $total,
        percent    => sprintf("%.1f", $percent), # 1 decimal

        # details
        sofar_secs => $sofar_secs,
        sofar_mins => $sofar_mins,
        total_secs => $total_secs,
        total_mins => $total_mins,
        left_secs  => $left_secs,
        left_mins  => $left_mins,
    };
    bless $self, $class;
    return $self;
}


1;

__END__

=pod

=head1 NAME

Audio::MPD::Time - class representing time of current song


=head1 SYNOPSIS

    my $time = $status->time;
    print $time->sofar;


=head1 DESCRIPTION

C<Audio::MPD::Status> returns some time information with the C<time()>
accessor. This information relates to the elapsed time of the current song,
as well as the remaining and total time. This information is encapsulated
in a C<Audio::MPD::Time> object.

Note that an C<Audio::MPD::Time> object does B<not> update itself regularly,
and thus should be used immediately.


=head1 METHODS

=head2 Constructor

=over 4

=item new( $time )

The C<new()> method is the constructor for the C<Audio::MPD::Time> class.
It is called internally during the C<Audio::MPD::Status> object creation,
with the C<time> line of the C<status> command sent to MPD server.

Note: one should B<never> ever instantiate an C<Audio::MPD::Time> object
directly - use the C<time()> method of C<Audio::MPD::Status>.

=back


=head2 Accessors

Once created, one can access to the following members of the object:

=over 4

=item cooked values:

The C<sofar()>, C<left()> and C<total()> methods return the according values
under the form C<minutes:seconds>. Note the existence of a C<percent()>
method returning a percentage complete. (one decimal)


=item values in seconds:

The C<seconds_sofar()>, C<seconds_left()> and C<seconds_total()> return the
according values in seconds.


=item detailled values:

If you want to cook your own value, then the following methods can help.
C<sofar_secs()> and C<sofar_mins()> return the seconds and minutes elapsed.
Same for C<left_secs()> and C<left_mins()> (time remaining), C<total_secs()>
and C<total_mins()>. (total song length)


=back


Please note that those accessors are read-only: changing a value will B<not>
change the current state of MPD server. Use C<Audio::MPD> methods to alter
the song playing.


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
