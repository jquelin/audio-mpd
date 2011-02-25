use 5.008;
use warnings;
use strict;

package Audio::MPD::Playlist;
# ABSTRACT: class to mess MPD's playlist

use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

has _mpd => ( ro, required, weak_ref );


#--
# Constructor

#
# my $collection = Audio::MPD::Playlist->new( _mpd => $mpd );
#
# This will create the object, holding a back-reference to the Audio::MPD
# object itself (for communication purposes). But in order to play safe and
# to free the memory in time, this reference is weakened.
#
# Note that you're not supposed to call this constructor yourself, an
# Audio::MPD::Playlist is automatically created for you during the creation
# of an Audio::MPD object.
#


#--
# Public methods

# -- Playlist: retrieving information

=meth_play_info as_items

    my @items = $pl->as_items;

Return an array of L<Audio::MPD::Common::Item::Song>s, one for each of the
songs in the current playlist.

=cut

sub as_items {
    my ($self) = @_;

    my @list = $self->_mpd->_cooked_command_as_items("playlistinfo\n");
    return @list;
}


=meth_play_info items_changed_since

    my @items = $pl->items_changed_since( $plversion );

Return a list with all the songs (as L<Audio::MPD::Common::Item::Song> objects)
added to the playlist since playlist C<$plversion>.

=cut

sub items_changed_since {
    my ($self, $plid) = @_;
    return $self->_mpd->_cooked_command_as_items("plchanges $plid\n");
}


# -- Playlist: adding / removing songs

=meth_play_addrm add

    $pl->add( $path [, $path [...] ] );

Add the songs identified by C<$path> (relative to MPD's music directory) to the
current playlist. No return value.

=cut

sub add {
    my ($self, @pathes) = @_;
    my $command =
          "command_list_begin\n"
        . join( '', map { my $p=$_; $p=~s/"/\\"/g; qq[add "$p"\n] } @pathes )
        . "command_list_end\n";
    $self->_mpd->_send_command( $command );
}


=meth_play_addrm delete

    $pl->delete( $song [, $song [...] ] );

Remove the specified C<$song> numbers (starting from 0) from the current
playlist. No return value.

=cut

sub delete {
    my ($self, @songs) = @_;
    my $command =
          "command_list_begin\n"
        . join( '', map { my $p=$_; $p=~s/"/\\"/g; "delete $p\n" } @songs )
        . "command_list_end\n";
    $self->_mpd->_send_command( $command );
}


=meth_play_addrm deleteid

    $pl->deleteid( $songid [, $songid [...] ] );

Remove the specified C<$songid>s (as assigned by mpd when inserted in playlist)
from the current playlist. No return value.

=cut

sub deleteid {
    my ($self, @songs) = @_;
    my $command =
          "command_list_begin\n"
        . join( '', map { "deleteid $_\n" } @songs )
        . "command_list_end\n";
    $self->_mpd->_send_command( $command );
}


=meth_play_addrm clear

    $pl->clear;

Remove all the songs from the current playlist. No return value.

=cut

sub clear {
    my ($self) = @_;
    $self->_mpd->_send_command("clear\n");
}


=meth_play_addrm crop

    $pl->crop;

Remove all of the songs from the current playlist B<except> the
song currently playing.

=cut

sub crop {
    my ($self) = @_;

    my $status = $self->_mpd->status;
    my $cur = $status->song;
    my $len = $status->playlistlength - 1;

    # we need to reverse the list, to remove the bigest ids before
    my $command =
          "command_list_begin\n"
        . join( '', map { $_  != $cur ? "delete $_\n" : '' } reverse 0..$len )
        . "command_list_end\n";
    $self->_mpd->_send_command( $command );
}


# -- Playlist: changing playlist order


=meth_play_order shuffle

    $pl->shuffle;

Shuffle the current playlist. No return value.

=cut

sub shuffle {
    my ($self) = @_;
    $self->_mpd->_send_command("shuffle\n");
}


=meth_play_order swap

    $pl->swap( $song1, $song2 );

Swap positions of song number C<$song1> and C<$song2> in the current
playlist. No return value.

=cut

sub swap {
    my ($self, $from, $to) = @_;
    $self->_mpd->_send_command("swap $from $to\n");
}


=meth_play_order swapid

    $pl->swapid( $songid1, $songid2 );

Swap the postions of song ID C<$songid1> with song ID C<$songid2> in the
current playlist. No return value.

=cut

sub swapid {
    my ($self, $from, $to) = @_;
    $self->_mpd->_send_command("swapid $from $to\n");
}


=meth_play_order move

    $pl->move( $song, $newpos );

Move song number C<$song> to the position C<$newpos>. No return value.

=cut

sub move {
    my ($self, $song, $pos) = @_;
    $self->_mpd->_send_command("move $song $pos\n");
}


=meth_play_order moveid

    $pl->moveid( $songid, $newpos );

Move song ID C<$songid> to the position C<$newpos>. No return value.

=cut

sub moveid {
    my ($self, $song, $pos) = @_;
    $self->_mpd->_send_command("moveid $song $pos\n");
}


# -- Playlist: managing playlists

=meth_play_mgmt load

    $pl->load( $playlist );

Load list of songs from specified C<$playlist> file. No return value.

=cut

sub load {
    my ($self, $playlist) = @_;
    $self->_mpd->_send_command( qq[load "$playlist"\n] );
}


=meth_play_mgmt save

    $pl->save( $playlist );

Save the current playlist to a file called C<$playlist> in MPD's playlist
directory. No return value.

=cut

sub save {
    my ($self, $playlist) = @_;
    $self->_mpd->_send_command( qq[save "$playlist"\n] );
}


=meth_play_mgmt rm

    $pl->rm( $playlist );

Delete playlist named C<$playlist> from MPD's playlist directory. No
return value.

=cut

sub rm {
    my ($self, $playlist) = @_;
    $self->_mpd->_send_command( qq[rm "$playlist"\n] );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

    $mpd->playlist->shuffle;
    # and lots of other methods


=head1 DESCRIPTION

L<Audio::MPD::Playlist> is a class meant to access & update MPD's
playlist.

Note that you're not supposed to call the constructor yourself, an
L<Audio::MPD::Playlist> is automatically created for you during the
creation of an L<Audio::MPD> object - it can then be used with the
C<playlist()> accessor.

