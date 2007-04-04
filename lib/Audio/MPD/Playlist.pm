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

package Audio::MPD::Playlist;

use strict;
use warnings;
use Scalar::Util qw[ weaken ];

use base qw[ Class::Accessor::Fast ];
__PACKAGE__->mk_accessors( qw[ _mpd ] );


#our ($VERSION) = '$Rev$' =~ /(\d+)/;


#--
# Constructor

#
# my $collection = Audio::MPD::Playlist->new( $mpd );
#
# This will create the object, holding a back-reference to the Audio::MPD
# object itself (for communication purposes). But in order to play safe and
# to free the memory in time, this reference is weakened.
#
# Note that you're not supposed to call this constructor yourself, an
# Audio::MPD::Playlist is automatically created for you during the creation
# of an Audio::MPD object.
#
sub new {
    my ($pkg, $mpd) = @_;

    my $self = { _mpd => $mpd };
    weaken( $self->{_mpd} );
    bless $self, $pkg;
    return $self;
}


#--
# Public methods

# -- Playlist: retrieving information

#
# my @items = $pl->as_items;
#
# Return an array of C<Audio::MPD::Item::Song>s, one for each of the
# songs in the current playlist.
#
sub as_items {
    my ($self) = @_;

    my @list = $self->_mpd->_cooked_command_as_items("playlistinfo\n");
    return @list;
}


#
# my @items = $pl->items_changed_since( $plversion );
#
# Return a list with all the songs (as API::Song objects) added to
# the playlist since playlist $plversion.
#
sub items_changed_since {
    my ($self, $plid) = @_;
    return $self->_mpd->_cooked_command_as_items("plchanges $plid\n");
}



# -- Playlist: adding / removing songs

#
# $pl->add( $path );
#
# Add the song identified by $path (relative to MPD's music directory) to
# the current playlist. No return value.
#
sub add {
    my ($self, $path) = @_;
    $self->_mpd->_send_command( qq[add "$path"\n] );
}


#
# $pl->delete( $song [, $song [...] ] );
#
# Remove song number $song (starting from 0) from the current playlist. No
# return value.
#
sub delete {
    my ($self, @songs) = @_;
    my $command =
          "command_list_begin\n"
        . join( '', map { "delete $_\n" } @songs )
        . "command_list_end\n";
    $self->_mpd->_send_command( $command );
}


#
# $pl->deleteid( $songid [, $songid [...] ]);
#
# Remove the specified $songid (as assigned by mpd when inserted in playlist)
# from the current playlist. No return value.
#
sub deleteid {
    my ($self, @songs) = @_;
    my $command =
          "command_list_begin\n"
        . join( '', map { "deleteid $_\n" } @songs )
        . "command_list_end\n";
    $self->_mpd->_send_command( $command );
}


#
# $pl->clear;
#
# Remove all the songs from the current playlist. No return value.
#
sub clear {
    my ($self) = @_;
    $self->_mpd->_send_command("clear\n");
}


#
# $pl->crop;
#
#  Remove all of the songs from the current playlist *except* the current one.
#
sub crop {
    my ($self) = @_;

    my $status = $self->_mpd->status;
    my $cur = $status->song;
    my $len = $status->playlistlength - 1;

    my $command =
          "command_list_begin\n"
        . join( '', map { $_  != $cur ? "delete $_\n" : '' } reverse 0..$len )
        . "command_list_end\n";
    $self->_mpd->_send_command( $command );
}


# -- Playlist: changing playlist order


sub swap {
    my ($self, $from, $to) = @_;
    $self->_send_command("swap $from $to\n");
}

sub swapid {
    my ($self, $from, $to) = @_;
    $self->_send_command("swapid $from $to\n");
}

sub shuffle {
    my ($self) = @_;
    $self->_send_command("shuffle\n");
}

sub move {
    my ($self, $song, $pos) = @_;
    $self->_send_command("move $song $pos\n");
}

sub moveid {
    my ($self, $song, $pos) = @_;
    $self->_send_command("moveid $song $pos\n");
}

sub load {
    my ($self, $playlist) = @_;
    return unless defined $playlist;
    $self->_send_command( qq[load "$playlist"\n] );
}

sub save {
    my ($self, $playlist) = @_;
    return unless defined $playlist;
    $self->_send_command( qq[save "$playlist"\n] );

=begin FIXME

    if(!$self->_process_feedback)
    {
        # Does the playlist already exist?
        if(${$self->get_error}[0] eq '56' && $config{'OVERWRITE_PLAYLIST'})
        {
            $self->rm($playlist);
            $self->save($playlist);
            return 1;
        }
    }
    return 1;

=end FIXME

=cut

}

sub rm {
    my ($self, $playlist) = @_;
    return unless defined $playlist;
    $self->_send_command( qq[rm "$playlist"\n] );
}



1;

__END__


=head1 NAME

Audio::MPD::Playlist - an object to mess MPD's playlist


=head1 SYNOPSIS

    my $song = $mpd->playlist->randomize;


=head1 DESCRIPTION

C<Audio::MPD::Playlist> is a class meant to access & update MPD's
playlist.


=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item new( $mpd )

This will create the object, holding a back-reference to the C<Audio::MPD>
object itself (for communication purposes). But in order to play safe and
to free the memory in time, this reference is weakened.

Note that you're not supposed to call this constructor yourself, an
C<Audio::MPD::Playlist> is automatically created for you during the creation
of an C<Audio::MPD> object.

=back


=head2 Retrieving information

=over 4

=item $pl->as_items( )

Return an array of C<Audio::MPD::Item::Song>s, one for each of the
songs in the current playlist.


=item $pl->items_changed_since( $plversion )

Return a list with all the songs (as API::Song objects) added to
the playlist since playlist $plversion.


=back


=head2 Adding / removing songs

=over 4

=item $pl->add( $path )

Add the song identified by C<$path> (relative to MPD's music directory) to the
current playlist. No return value.


=item $pl->delete( $song [, $song [...] ] )

Remove song number C<$song>s (starting from 0) from the current playlist. No
return value.


=item $pl->deleteid( $songid [, $songid [...] ] )

Remove the specified C<$songid>s (as assigned by mpd when inserted in playlist)
from the current playlist. No return value.


=item $pl->clear()

Remove all the songs from the current playlist. No return value.


=item $pl->crop()

Remove all of the songs from the current playlist *except* the
song currently playing.


=back


=head2 Changing playlist order

=over 4

=item $pl->swap( $song1, $song2 )

Swap positions of song number $song1 and $song2 on the current playlist. No
return value.


=item $pl->swapid( $songid1, $songid2 )

Swap the postions of song ID $songid1 with song ID $songid2 on the current
playlist. No return value.


=item $pl->move( $song, $newpos )

Move song number $song to the position $newpos. No return value.


=item $pl->moveid( $songid, $newpos )

Move song ID $songid to the position $newpos. No return value.


=item $pl->shuffle()

Shuffle the current playlist. No return value.


=item $pl->load( $playlist )

Load list of songs from specified $playlist file. No return value.


=item $pl->save( $playlist )

Save the current playlist to a file called $playlist in MPD's playlist
directory. No return value.


=item $pl->rm( $playlist )

Delete playlist named $playlist from MPD's playlist directory. No return value.

=back


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
