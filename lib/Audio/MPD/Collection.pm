use 5.008;
use warnings;
use strict;

package Audio::MPD::Collection;
# ABSTRACT: class to query MPD's collection

use Moose;
use MooseX::SemiAffordanceAccessor;

has _mpd => ( is=>'ro', required=>1, weak_ref=>1 );


#--
# Constructor

#
# my $collection = Audio::MPD::Collection->new( _mpd => $mpd );
#
# This will create the object, holding a back-reference to the Audio::MPD
# object itself (for communication purposes). But in order to play safe and
# to free the memory in time, this reference is weakened.
#
# Note that you're not supposed to call this constructor yourself, an
# Audio::MPD::Collection is automatically created for you during the creation
# of an Audio::MPD object.
#


#--
# Public methods

# -- Collection: retrieving songs & directories

=meth_mpd_playback my @items = $coll->all_items( [$path] );

Return B<all> L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

=cut

sub all_items {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[listallinfo "$path"\n] );
}


=meth_coll_song my @items = $coll->all_items_simple( [$path] );

Return B<all> L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

B</!\ Warning>: the L<Audio::MPD::Common::Item::Song> objects will only
have their tag C<file> filled. Any other tag will be empty, so don't use
this sub for any other thing than a quick scan!

=cut

sub all_items_simple {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[listall "$path"\n] );
}


=meth_coll_song my @items = $coll->items_in_dir( [$path] );

Return the items in the given C<$path>. If no C<$path> supplied, do it on
mpd's root directory.

Note that this sub does not work recusrively on all directories.

=cut

sub items_in_dir {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[lsinfo "$path"\n] );
}


# -- Collection: retrieving the whole collection

=meth_coll_whole my @songs = $coll->all_songs( [$path] );

Return B<all> L<Audio::MPD::Common::Item::Song>s currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

=cut

sub all_songs {
    my ($self, $path) = @_;
    return grep { $_->isa('Audio::MPD::Common::Item::Song') } $self->all_items($path);
}


=meth_coll_whole my @albums = $coll->all_albums;

Return the list of all albums (strings) currently known by mpd.

=cut

sub all_albums {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list album\n" );
}


=meth_coll_whole my @artists = $coll->all_artists;

Return the list of all artists (strings) currently known by mpd.

=cut

sub all_artists {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list artist\n" );
}


=meth_coll_whole my @titles = $coll->all_titles;

Return the list of all song titles (strings) currently known by mpd.

=cut

sub all_titles {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list title\n" );
}


=meth_coll_whole my @pathes = $coll->all_pathes;

Return the list of all pathes (strings) currently known by mpd.

=cut

sub all_pathes {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list filename\n" );
}


=meth_coll_whole my @lists = $coll->all_playlists;

Return the list of all playlists (strings) currently known by mpd.

=cut

sub all_playlists {
    my ($self) = @_;

    return
        map { /^playlist: (.*)$/ ? ($1) : () }
        $self->_mpd->_send_command( "lsinfo\n" );
}


# -- Collection: picking songs

=meth_coll_pick my $song = $coll->song( $path );

Return the L<Audio::MPD::Common::Item::Song> which correspond to C<$path>.

=cut

sub song {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    my ($item) = $self->_mpd->_cooked_command_as_items( qq[find filename "$what"\n] );
    return $item;
}


=meth_coll_pick my @songs = $coll->songs_with_filename_partial( $string );

Return the L<Audio::MPD::Common::Item::Song>s containing C<$string> in
their path.

=cut

sub songs_with_filename_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search filename "$what"\n] );
}


# -- Collection: songs, albums & artists relations

=meth_coll_relations my @albums = $coll->albums_by_artist( $artist );

Return all albums (strings) performed by C<$artist> or where C<$artist>
participated.

=cut

sub albums_by_artist {
    my ($self, $artist) = @_;
    $artist =~ s/"/\\"/g;
    return $self->_mpd->_cooked_command_strip_first_field( qq[list album "$artist"\n] );
}


=meth_coll_relations my @songs = $coll->songs_by_artist( $artist );

Return all L<Audio::MPD::Common::Item::Song>s performed by C<$artist>.

=cut

sub songs_by_artist {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find artist "$what"\n] );
}


=meth_coll_relations my @songs = $coll->songs_by_artist_partial( $string );

Return all L<Audio::MPD::Common::Item::Song>s performed by an artist
with C<$string> in her name.

=cut

sub songs_by_artist_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search artist "$what"\n] );
}


=meth_coll_relations my @songs = $coll->songs_from_album( $album );

Return all L<Audio::MPD::Common::Item::Song>s appearing in C<$album>.

=cut

sub songs_from_album {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find album "$what"\n] );
}


=meth_coll_relations my @songs = $coll->songs_from_album_partial( $string );

Return all L<Audio::MPD::Common::Item::Song>s appearing in album
containing C<$string>.

=cut

sub songs_from_album_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search album "$what"\n] );
}

=meth_coll_relations my @songs = $coll->songs_with_title( $title );

Return all L<Audio::MPD::Common::Item::Song>s which title is exactly
C<$title>.

=cut

sub songs_with_title {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find title "$what"\n] );
}


=meth_coll_relations my @songs = $coll->songs_with_title_partial( $string );

Return all L<Audio::MPD::Common::Item::Song>s where C<$string> is part
of the title.

=cut

sub songs_with_title_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search title "$what"\n] );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

    my @songs = $mpd->collection->all_songs;
    # and lots of other methods


=head1 DESCRIPTION

L<Audio::MPD::Collection> is a class meant to access & query MPD's
collection. You will be able to use those high-level methods instead
of using the low-level methods provided by mpd itself.

Note that you're not supposed to call the constructor yourself, an
L<Audio::MPD::Collection> is automatically created for you during the
creation of an L<Audio::MPD> object - it can then be used with the
C<collection()> accessor.
