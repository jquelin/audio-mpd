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

package Audio::MPD::Collection;

use strict;
use warnings;
use Audio::MPD::Item::Directory;
use Audio::MPD::Item::Song;
use Scalar::Util qw[ weaken ];

use base qw[ Class::Accessor::Fast ];
__PACKAGE__->mk_accessors( qw[ _mpd ] );


#our ($VERSION) = '$Rev: 5645 $' =~ /(\d+)/;


#--
# Constructor

#
# my $collection = Audio::MPD::Collection->new( $mpd );
#
# This will create the object, holding a back-reference to the Audio::MPD
# object itself (for communication purposes). But in order to play safe and
# to free the memory in time, this reference is weakened.
#
# Note that you're not supposed to call this constructor yourself, an
# Audio::MPD::Collection is automatically created for you during the creation
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

# -- Collection: retrieving songs & directories

#
# my @items = $collection->all_items( [$path] );
#
# Return *all* Audio::MPD::Items (both songs & directories) currently known
# by mpd.
#
# If $path is supplied (relative to mpd root), restrict the retrieval to
# songs and dirs in this directory.
#
sub all_items {
    my ($self, $path) = @_;
    $path ||= '';

    my @lines = $self->_mpd->_send_command( qq[listallinfo "$path"\n] );
    my (@list, %param);

    # parse lines in reverse order since "file:" comes first.
    # therefore, let's first store every other parameter, and
    # the "file:" line will trigger the object creation.
    # of course, since we want to preserve the playlist order,
    # this means that we're going to unshift the objects.
    foreach my $line (reverse @lines) {
        next unless $line =~ /^([^:]+):\s+(.+)$/;
        $param{$1} = $2;
        next unless $1 eq 'file' || $1 eq 'directory'; # last param of item
        unshift @list, Audio::MPD::Item->new(%param);
        %param = ();
    }
    return @list;
}


#
# my @items = $collection->all_items_simple( [$path] );
#
# Return *all* Audio::MPD::Items (both songs & directories) currently known
# by mpd.
#
# If $path is supplied (relative to mpd root), restrict the retrieval to
# songs and dirs in this directory.
#
# /!\ Warning: the Audio::MPD::Item::Song objects will only have their tag
# file filled. Any other tag will be empty, so don't use this sub for any
# other thing than a quick scan!
#
sub all_items_simple {
    my ($self, $path) = @_;
    $path ||= '';

    my @lines = $self->_mpd->_send_command( qq[listall "$path"\n] );
    my (@list, %param);

    # parse lines in reverse order since "file:" comes first.
    # therefore, let's first store every other parameter, and
    # the "file:" line will trigger the object creation.
    # of course, since we want to preserve the playlist order,
    # this means that we're going to unshift the objects.
    foreach my $line (reverse @lines) {
        next unless $line =~ /^([^:]+):\s+(.+)$/;
        $param{$1} = $2;
        next unless $1 eq 'file' || $1 eq 'directory'; # last param of item
        unshift @list, Audio::MPD::Item->new(%param);
        %param = ();
    }
    return @list;
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

    my @lines = $self->_mpd->_send_command( qq[lsinfo "$path"\n] );
    my (@list, %param);

    # parse lines in reverse order since "file:" comes first.
    # therefore, let's first store every other parameter, and
    # the "file:" line will trigger the object creation.
    # of course, since we want to preserve the playlist order,
    # this means that we're going to unshift the objects.
    foreach my $line (reverse @lines) {
        next unless $line =~ /^([^:]+):\s+(.+)$/;
        $param{$1} = $2;
        next unless $1 eq 'file' || $1 eq 'directory'; # last param of item
        unshift @list, Audio::MPD::Item->new(%param);
        %param = ();
    }
    return @list;
}



# -- Collection: retrieving the whole collection

#
# my @albums = $collection->all_albums;
#
# Return the list of all albums (strings) currently known by mpd.
#
sub all_albums {
    my ($self) = @_;
    return
        map { /^Album: (.+)$/ ? $1 : () }
        $self->_mpd->_send_command( "list album\n" );
}


#
# my @artists = $collection->all_artists;
#
# Return the list of all artists (strings) currently known by mpd.
#
sub all_artists {
    my ($self) = @_;
    return
        map { /^Artist: (.+)$/ ? $1 : () }
        $self->_mpd->_send_command( "list artist\n" );
}


#
# my @titles = $collection->all_titles;
#
# Return the list of all titles (strings) currently known by mpd.
#
sub all_titles {
    my ($self) = @_;
    return
        map { /^Title: (.+)$/ ? $1 : () }
        $self->_mpd->_send_command( "list title\n" );
}


#
# my @pathes = $collection->all_pathes;
#
# Return the list of all pathes (strings) currently known by mpd.
#
sub all_pathes {
    my ($self) = @_;
    return
        map { /^file: (.+)$/ ? $1 : () }
        $self->_mpd->_send_command( "list filename\n" );
}


# -- Collection: picking a song

#
# my $song = $collection->song( $path );
#
# Return the Audio::MPD::Item::Song which correspond to $path.
#
sub song {
    my ($self, $what) = @_;

    my @lines = $self->_mpd->_send_command( qq[find filename "$what"\n] );
    my %param;

    # parse lines in reverse order since "file:" comes first.
    # therefore, let's first store every other parameter, and
    # the "file:" line will trigger the object creation.
    # of course, since we want to preserve the playlist order,
    # this means that we're going to unshift the objects.
    foreach my $line (reverse @lines) {
        next unless $line =~ /^([^:]+):\s+(.+)$/;
        $param{$1} = $2;
        next unless $1 eq 'file'; # last param of this item
        return Audio::MPD::Item->new(%param);
    }
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
    return
        map { /^Album: (.+)$/ ? $1 : () }
        $self->_mpd->_send_command( qq[list album "$artist"\n] );
}


#
# my @songs = $collection->songs_by_artist( $artist );
#
# Return all Audio::MPD::Item::Songs performed by $artist.
#
sub songs_by_artist {
    my ($self, $what) = @_;

    my @lines = $self->_mpd->_send_command( qq[find artist "$what"\n] );
    my (@list, %param);

    # parse lines in reverse order since "file:" comes first.
    # therefore, let's first store every other parameter, and
    # the "file:" line will trigger the object creation.
    # of course, since we want to preserve the playlist order,
    # this means that we're going to unshift the objects.
    foreach my $line (reverse @lines) {
        next unless $line =~ /^([^:]+):\s+(.+)$/;
        $param{$1} = $2;
        next unless $1 eq 'file'; # last param of this item
        unshift @list, Audio::MPD::Item->new(%param);
        %param = ();
    }
    return @list;
}


#
# my @songs = $collection->songs_from_album( $album );
#
# Return all Audio::MPD::Item::Songs appearing in $album.
#
sub songs_from_album {
    my ($self, $what) = @_;

    my @lines = $self->_mpd->_send_command( qq[find album "$what"\n] );
    my (@list, %param);

    # parse lines in reverse order since "file:" comes first.
    # therefore, let's first store every other parameter, and
    # the "file:" line will trigger the object creation.
    # of course, since we want to preserve the playlist order,
    # this means that we're going to unshift the objects.
    foreach my $line (reverse @lines) {
        next unless $line =~ /^([^:]+):\s+(.+)$/;
        $param{$1} = $2;
        next unless $1 eq 'file'; # last param of this item
        unshift @list, Audio::MPD::Item->new(%param);
        %param = ();
    }
    return @list;
}


#
# my @songs = $collection->songs_with_title( $title );
#
# Return all Audio::MPD::Item::Songs which title is exactly $title.
#
sub songs_with_title {
    my ($self, $what) = @_;

    my @lines = $self->_mpd->_send_command( qq[find title "$what"\n] );
    my (@list, %param);

    # parse lines in reverse order since "file:" comes first.
    # therefore, let's first store every other parameter, and
    # the "file:" line will trigger the object creation.
    # of course, since we want to preserve the playlist order,
    # this means that we're going to unshift the objects.
    foreach my $line (reverse @lines) {
        next unless $line =~ /^([^:]+):\s+(.+)$/;
        $param{$1} = $2;
        next unless $1 eq 'file'; # last param of this item
        unshift @list, Audio::MPD::Item->new(%param);
        %param = ();
    }
    return @list;
}


1;

__END__


=head1 NAME

Audio::MPD::Collection - an object to query MPD's collection


=head1 SYNOPSIS

    my $song = $mpd->collection->random_song;


=head1 DESCRIPTION

C<Audio::MPD::Collection> is a class meant to access & query MPD's
collection. You will be able to use those high-level methods instead
of using the low-level methods provided by mpd itself.


=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item new( $mpd )

This will create the object, holding a back-reference to the C<Audio::MPD>
object itself (for communication purposes). But in order to play safe and
to free the memory in time, this reference is weakened.

Note that you're not supposed to call this constructor yourself, an
C<Audio::MPD::Collection> is automatically created for you during the creation
of an C<Audio::MPD> object.

=back


=head2 Retrieving songs & directories

=over 4

=item all_items( [$path] )

Return B<all> C<Audio::MPD::Item>s (both songs & directories) currently known
by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.


=item all_items_simple( [$path] )

Return B<all> C<Audio::MPD::Item>s (both songs & directories) currently known
by mpd.

If C<$path> is supplied (relative to mpd root), restrict the retrieval to
songs and dirs in this directory.

B</!\ Warning>: the C<Audio::MPD::Item::Song> objects will only have their
tag file filled. Any other tag will be empty, so don't use this sub for any
other thing than a quick scan!


=item items_in_dir( [$path] )

Return the items in the given C<$path>. If no C<$path> supplied, do it on
mpd's root directory.

Note that this sub does not work recusrively on all directories.


=back


=head2 Retrieving the whole collection

=over 4

=item all_albums()

Return the list of all albums (strings) currently known by mpd.


=item all_artists()

Return the list of all artists (strings) currently known by mpd.


=item all_titles()

Return the list of all song titles (strings) currently known by mpd.


=item all_pathes()

Return the list of all pathes (strings) currently known by mpd.


=back


=head2 Picking a song

=over 4

=item song( $path )

Return the C<Audio::MPD::Item::Song> which correspond to C<$path>.


=back


=head2 Songs, albums & artists relations

=over 4

=item albums_by_artist( $artist )

Return all albums (strings) performed by C<$artist> or where C<$artist>
participated.


=item songs_by_artist( $artist )

Return all C<Audio::MPD::Item::Song>s performed by C<$artist>.


=item songs_from_album( $album )

Return all C<Audio::MPD::Item::Song>s appearing in C<$album>.


=item songs_with_title( $title )

Return all C<Audio::MPD::Item::Song>s which title is exactly C<$title>.


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
