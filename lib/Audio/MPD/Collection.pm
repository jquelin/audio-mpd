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

#
# my @items = $collection->all_items( [$path] );
#
# Return *all* AMC::Items (both songs & directories) currently known
# by mpd.
#
# If $path is supplied (relative to mpd root), restrict the retrieval to
# songs and dirs in this directory.
#
sub all_items {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[listallinfo "$path"\n] );
}


#
# my @items = $collection->all_items_simple( [$path] );
#
# Return *all* AMC::Items (both songs & directories) currently known
# by mpd.
#
# If $path is supplied (relative to mpd root), restrict the retrieval to
# songs and dirs in this directory.
#
# /!\ Warning: the AMC::Item::Song objects will only have their tag
# file filled. Any other tag will be empty, so don't use this sub for any
# other thing than a quick scan!
#
sub all_items_simple {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[listall "$path"\n] );
}


#
# my @items = $collection->items_in_dir( [$path] );
#
# Return the items in the given $path. If no $path supplied, do it on mpd's
# root directory.
#
# Note that this sub does not work recusrively on all directories.
#
sub items_in_dir {
    my ($self, $path) = @_;
    $path ||= '';
    $path =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[lsinfo "$path"\n] );
}



# -- Collection: retrieving the whole collection

#
# my @songs = $collection->all_songs( [$path] );
#
# Return *all* AMC::Item::Songs currently known by mpd.
#
# If $path is supplied (relative to mpd root), restrict the retrieval to
# songs and dirs in this directory.
#
sub all_songs {
    my ($self, $path) = @_;
    return grep { $_->isa('Audio::MPD::Common::Item::Song') } $self->all_items($path);
}


#
# my @albums = $collection->all_albums;
#
# Return the list of all albums (strings) currently known by mpd.
#
sub all_albums {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list album\n" );
}


#
# my @artists = $collection->all_artists;
#
# Return the list of all artists (strings) currently known by mpd.
#
sub all_artists {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list artist\n" );
}


#
# my @titles = $collection->all_titles;
#
# Return the list of all titles (strings) currently known by mpd.
#
sub all_titles {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list title\n" );
}


#
# my @pathes = $collection->all_pathes;
#
# Return the list of all pathes (strings) currently known by mpd.
#
sub all_pathes {
    my ($self) = @_;
    return $self->_mpd->_cooked_command_strip_first_field( "list filename\n" );
}


#
# my @items = $collection->all_playlists;
#
# Return the list of playlists (strings) currently known by mpd.
#
sub all_playlists {
    my ($self) = @_;

    return
        map { /^playlist: (.*)$/ ? ($1) : () }
        $self->_mpd->_send_command( "lsinfo\n" );
}



# -- Collection: picking songs

#
# my $song = $collection->song( $path );
#
# Return the AMC::Item::Song which correspond to $path.
#
sub song {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    my ($item) = $self->_mpd->_cooked_command_as_items( qq[find filename "$what"\n] );
    return $item;
}


#
# my $song = $collection->songs_with_filename_partial( $string );
#
# Return the AMC::Item::Songs containing $string in their path.
#
sub songs_with_filename_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search filename "$what"\n] );
}


# -- Collection: songs, albums & artists relations

#
# my @albums = $collection->albums_by_artist($artist);
#
# Return all albums (strings) performed by $artist or where $artist
# participated.
#
sub albums_by_artist {
    my ($self, $artist) = @_;
    $artist =~ s/"/\\"/g;
    return $self->_mpd->_cooked_command_strip_first_field( qq[list album "$artist"\n] );
}


#
# my @songs = $collection->songs_by_artist( $artist );
#
# Return all AMC::Item::Songs performed by $artist.
#
sub songs_by_artist {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find artist "$what"\n] );
}


#
# my @songs = $collection->songs_by_artist_partial( $string );
#
# Return all AMC::Item::Songs performed by an artist with $string
# in her name.
#
sub songs_by_artist_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search artist "$what"\n] );
}


#
# my @songs = $collection->songs_from_album( $album );
#
# Return all AMC::Item::Songs appearing in $album.
#
sub songs_from_album {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find album "$what"\n] );
}


#
# my @songs = $collection->songs_from_album_partial( $string );
#
# Return all AMC::Item::Songs appearing in album containing $string.
#
sub songs_from_album_partial {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[search album "$what"\n] );
}


#
# my @songs = $collection->songs_with_title( $title );
#
# Return all AMC::Item::Songs which title is exactly $title.
#
sub songs_with_title {
    my ($self, $what) = @_;
    $what =~ s/"/\\"/g;

    return $self->_mpd->_cooked_command_as_items( qq[find title "$what"\n] );
}


#
# my @songs = $collection->songs_with_title_partial( $string );
#
# Return all AMC::Item::Songs where $string is part of the title.
#
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

    my $song = $mpd->collection->random_song;


=head1 DESCRIPTION

L<Audio::MPD::Collection> is a class meant to access & query MPD's
collection. You will be able to use those high-level methods instead
of using the low-level methods provided by mpd itself.

Note that you're not supposed to call the constructor yourself, an
L<Audio::MPD::Collection> is automatically created for you during the
creation of an L<Audio::MPD> object - it can then be used with the
C<collection()> accessor.


=head1 PUBLIC METHODS

=head2 Retrieving songs & directories

=over 4

=item $coll->all_items( [$path] )

Return B<all> L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.


=item $coll->all_items_simple( [$path] )

Return B<all> L<Audio::MPD::Common::Item>s (both songs & directories)
currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

B</!\ Warning>: the L<Audio::MPD::Common::Item::Song> objects will only
have their tag C<file> filled. Any other tag will be empty, so don't use
this sub for any other thing than a quick scan!


=item $coll->items_in_dir( [$path] )

Return the items in the given C<$path>. If no C<$path> supplied, do it on
mpd's root directory.

Note that this sub does not work recusrively on all directories.


=back


=head2 Retrieving the whole collection

=over 4

=item $coll->all_songs( [$path] )

Return B<all> L<Audio::MPD::Common::Item::Song>s currently known by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.


=item $coll->all_albums()

Return the list of all albums (strings) currently known by mpd.


=item $coll->all_artists()

Return the list of all artists (strings) currently known by mpd.


=item $coll->all_titles()

Return the list of all song titles (strings) currently known by mpd.


=item $coll->all_pathes()

Return the list of all pathes (strings) currently known by mpd.


=item $coll->all_playlists()

Return the list of all playlists (strings) currently known by mpd.


=back


=head2 Picking a song

=over 4

=item $coll->song( $path )

Return the L<Audio::MPD::Common::Item::Song> which correspond to C<$path>.


=item $coll->songs_with_filename_partial( $string )

Return the L<Audio::MPD::Common::Item::Song>s containing C<$string> in
their path.


=back


=head2 Songs, albums & artists relations

=over 4

=item $coll->albums_by_artist( $artist )

Return all albums (strings) performed by C<$artist> or where C<$artist>
participated.


=item $coll->songs_by_artist( $artist )

Return all L<Audio::MPD::Common::Item::Song>s performed by C<$artist>.


=item $coll->songs_by_artist_partial( $string )

Return all L<Audio::MPD::Common::Item::Song>s performed by an artist
with C<$string> in her name.


=item $coll->songs_from_album( $album )

Return all L<Audio::MPD::Common::Item::Song>s appearing in C<$album>.


=item $coll->songs_from_album_partial( $string )

Return all L<Audio::MPD::Common::Item::Song>s appearing in album
containing C<$string>.


=item $coll->songs_with_title( $title )

Return all L<Audio::MPD::Common::Item::Song>s which title is exactly
C<$title>.


=item $coll->songs_with_title_partial( $string )

Return all L<Audio::MPD::Common::Item::Song>s where C<$string> is part
of the title.


=back


