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

package Audio::MPD;

use warnings;
use strict;

use Audio::MPD::Status;
use IO::Socket;


use base qw[ Class::Accessor::Fast ];
__PACKAGE__->mk_accessors( qw[ _host _password _port version ] );


our $VERSION = '0.13.1';


#--
# Constructor

#
# my $mpd = Audio::MPD->new( [$hostname], [$port], [$password] )
#
# This is the constructor for Audio::MPD. One can specify a $hostname, a
# $port, and a $password.
# If none is specified then defaults to environment vars MPD_HOST, MPD_PORT
# and MPD_PASSWORD. If those aren't set, defaults to 'localhost', 6600 and ''.
#
sub new {
    my $class = shift;
    my ($host, $port, $password) = @_;

    # use mpd defaults.
    $host     ||= $ENV{MPD_HOST}     || 'localhost';
    $port     ||= $ENV{MPD_PORT}     || '6600';
    $password ||= $ENV{MPD_PASSWORD} || '';

    # create & bless the object.
    my $self = {
        _host     => $host,
        _port     => $port,
        _password => $password,
    };
    bless $self, $class;

    # try to issue a ping to test connection - this can die.
    $self->ping;

    return $self;
}



#--
# Public methods


#
# $mpd->ping;
#
# Sends a ping command to the mpd server.
#
sub ping {
    my ($self) = @_;
    $self->_send_command( "ping\n" );
}


sub stats {
    my ($self) = @_;
    my %kv =
        map { /^([^:]+):\s+(\S+)$/ ? ($1 => $2) : () }
        $self->_send_command( "stats\n" );
    return \%kv;
}


sub status {
    my ($self) = @_;
    my @output = $self->_send_command( "status\n" );
    my $status = Audio::MPD::Status->new( @output );
    return $status;
}


#--
# Private methods



#
# my @result = $mpd->_send_command( $command );
#
# This method is central to the module. It is responsible for interacting with
# mpd by sending the $command and reading output - that will be returned as an
# array of chomped lines (status line will not be returned).
#
# Note that currently, this method will connect to mpd before sending any
# command, and will disconnect after the command has been issued. This scheme
# is far from optimal, but allows us not to care about timeout disconnections.
#
# /!\ Note that we're using high-level, blocking sockets. This means that if
# the mpd server is slow, or hangs for whatever reason, or even crash abruptly,
# the program will be hung forever in this sub. The POE::Component::Client::MPD
# module is way safer - you're advised to use it instead of Audio::MPD.
#
# This method can die on several conditions:
#  - if the server cannot be reached,
#  - if it's not an mpd server,
#  - if the password is incorrect,
#  - or if the command is an invalid mpd command.
# In the latter case, the mpd error message will be returned.
#
sub _send_command {
    my ($self, $command) = @_;

    # try to connect to mpd.
    my $socket = IO::Socket::INET->new(
        PeerAddr => $self->_host,
        PeerPort => $self->_port
    )
    or die "Could not create socket: $!\n";
    my $line;

    # parse version information.
    $line = $socket->getline;
    chomp $line;
    die "Not a mpd server - welcome string was: [$line]\n"
        if $line !~ /^OK MPD (.+)$/;
    $self->version($1);

    # send password.
    if ( $self->_password ) {
        $socket->print( 'password ' . $self->_password . "\n" );
        $line = $socket->getline;
        die $line if $line =~ s/^ACK //;
    }

    # ok, now we're connected - let's issue the command.
    $socket->print( $command );
    my @output;
    while (defined ( $line = $socket->getline ) ) {
        chomp $line;
        die $line if $line =~ s/^ACK //; # oops - error.
        last if $line =~ /^OK/;          # end of output.
        push @output, $line;
    }

    # close the socket.
    $socket->close;

    return @output;
}





###############################################################
#                       BASIC METHODS                         #
#-------------------------------------------------------------#
#  This section contains all basic methods for the module to  #
#     function, internal methods and methods not returning    #
#      or altering information about playback and alike.      #
###############################################################


sub kill {
    my ($self) = @_;
    $self->_send_command("kill\n");
}

sub send_password {
    my ($self) = @_;
    $self->ping; # ping sends a command, and thus the password is sent
}

sub get_urlhandlers {
    my ($self) = @_;
    my @handlers =
        map { /^handler: (.+)$/ ? $1 : () }
        $self->_send_command("urlhandlers\n");
    return @handlers;
}


###############################################################
#               METHODS FOR ALTERING SETTINGS                 #
#-------------------------------------------------------------#
#  This section contains methods used for altering different  #
#                     settings in MPD.                        #
###############################################################

sub repeat {
    my ($self, $mode) = @_;

    $mode ||= not $self->status->repeat; # toggle if no param
    $mode = $mode ? 1 : 0;               # force integer
    $self->_send_command("repeat $mode\n");
}

sub random {
    my ($self, $mode) = @_;

    $mode ||= not $self->status->random; # toggle if no param
    $mode = $mode ? 1 : 0;               # force integer
    $self->_send_command("random $mode\n");
}

sub fade {
    my ($self, $value) = @_;
    $value ||= 0;
    $self->_send_command("crossfade $value\n");
}

sub volume {
    my ($self, $volume) = @_;

    if ($volume =~ /^(-|\+)(\d+)/ )  {
        my $current = $self->status->volume;
        $volume = $1 eq '+' ? $current + $2 : $current - $1;
    }
    $self->_send_command("setvol $volume\n");
}

sub output_enable {
    my ($self, $output) = @_;
    $self->_send_command("enableoutput $output\n");
}

sub output_disable {
    my ($self, $output) = @_;
    $self->_send_command("disableoutput $output\n");
}

###############################################################
#                METHODS FOR COMMON PLAYBACK                  #
#-------------------------------------------------------------#
#   This section contains the most commonly used methods for  #
#                    altering playback.                       #
###############################################################

sub play {
    my ($self, $number) = @_;
    $number ||= '';
    $self->_send_command("play $number");
}

sub playid {
    my ($self, $number) = @_;
    $number ||= '';
    $self->_send_command("playid $number");
}

sub pause {
    my ($self, $state) = @_;
    $state ||= ''; # default is to toggle
    $self->_send_command("pause $state\n");
}

sub stop {
    my ($self) = @_;
    $self->_send_command("stop\n");
}

sub next {
    my ($self) = @_;
    $self->_send_command("next\n");
}

sub prev {
    my($self) = shift;
    $self->_send_command("previous\n");
}

sub seek {
    my ($self, $time, $song) = @_;
    $time ||= 0; $time = int $time;
    $song = $self->status->song || 0 if not defined $song; # seek in current song
    $self->_send_command( "seek $song $time\n" );
}

sub seekid {
    my ($self, $time, $song) = @_;
    $time ||= 0; $time = int $time;
    $song ||= 0; $song = int $song;
    $self->_send_command( "seekid $song $time\n" );
}

###############################################################
#               METHODS FOR PLAYLIST-HANDLING                 #
#-------------------------------------------------------------#
#  This section contains all methods which has anything to do #
#            with the current or saved playlists.             #
###############################################################

#
# $mpd->clear()
#
# Remove all the songs from the current playlist. No return value.
#
sub clear {
    my ($self) = @_;
    $self->_send_command("clear\n");
}



sub add {
    my ($self, $path) = @_;
    return unless defined $path;
    $self->_send_command( qq[add "$path"\n] );
}

sub delete {
    my ($self, @songs) = @_;
    my $command =
          "command_list_begin\n"
        . join( '', map { "delete $_\n" } @songs )
        . "command_list_end\n";
    $self->_send_command( $command );
}

sub deleteid {
    my ($self, @songs) = @_;
    my $command =
          "command_list_begin\n"
        . join( '', map { "delete $_\n" } @songs )
        . "command_list_end\n";
    $self->_send_command( $command );
}

sub load {
    my ($self, $playlist) = @_;
    return unless defined $playlist;
    $self->_send_command( qq[load "$playlist"\n] );
}

sub updatedb {
    my ($self, $path) = @_;
    $path ||= '';
    $self->_send_command("update $path\n");
}

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

sub rm {
    my ($self, $playlist) = @_;
    return unless defined $playlist;
    $self->_send_command( qq[rm "$playlist"\n] );
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

sub search {
    my ($self, $type, $string, $strict) = @_;

    my $command = (!defined($strict) || $strict == 0 ? 'search' : 'find');
    my @lines = $self->_send_command( qq[$command $type "$string"\n] );

    my @list;
    my %hash;
    foreach my $line (@lines) {
        next unless $line =~ /^([^:]+):\s(.+)$/;
        if ($1 eq 'file') {
            push @list, { %hash } if %hash;
            %hash = ();
        }
        $hash{$1} = $2;
    }
    push @list, { %hash }; # Remember the last entry
    return @list;
}

sub list {
    my ($self, $type, $artist) = @_;
    my $command = "list $type " . $type eq 'album' ? qq["$artist"] : '';
    return
        map { /^[^:]+:\s+(.*)$/ ? $1 : () }
        $self->_send_command( "$command\n" );
}

# recursively, but only dirs & files
sub listall {
    my ($self, $path) = @_;
    $path ||= '';
    return $self->_send_command( qq[listall "$path"\n] );
    # FIXME: return item::songs / item::directory
}

# recursive, with all tags
sub listallinfo {
    my ($self, $path) = @_;
    $path ||= '';
    my @lines = $self->_send_command( qq[listallinfo "$path"\n] );

    my @results;
    my %element;
    foreach my $line (@lines) {
        chomp $line;
        next unless $line =~ /^([^:]+):\s(.+)$/;
        if ($1 eq 'file') {
            push @results, { %element } if %element;
            %element = ();
        }
        $element{$1} = $2;
    }
    push @results, { %element };
    return @results;
    # FIXME: return item::songs / item::directory
}

# only in the current path, all tags
sub lsinfo {
    my ($self, $path) = @_;
    $path ||= '';

    my @lines = $self->_send_command( qq[lsinfo "$path"\n] );

    my @results;
    my %element;
    foreach my $line (@lines) {
        chomp $line;
        next unless $line =~ /^([^:]+):\s(.+)$/;
        if ($1 eq 'file' || $1 eq 'playlist' || $1 eq 'directory') {
            push @results, { %element } if %element;
            %element = ();
        }
        $element{$1} = $2;
    }
    push @results, { %element };
    return @results;
    # FIXME: return item::songs / item::directory
}


###############################################################
#                     CUSTOM METHODS                          #
#-------------------------------------------------------------#
#   This section contains all methods not directly accessing  #
#   MPD, but may be useful for most people using the module.  #
###############################################################

sub get_song_info {
    my ($self, $song) = @_;
    $song ||= $self->status->song;
    return
        map { /^([^:]+):\s(.+)$/ ? ($1=>$2) : () }
        $self->_send_command("playlistinfo $song\n");
    # FIXME: return item::songs / item::directory
}

sub get_current_song_info {
    my ($self) = @_;
    return
        map { /^([^:]+):\s(.+)$/ ? ($1=>$2) : () }
        $self->_send_command("currentsong\n");
    # FIXME: return item::songs / item::directory
}

sub get_song_info_from_id {
    my ($self, $song) = @_;
    $song ||= $self->status->song;
    return
        map { /^([^:]+):\s(.+)$/ ? ($1=>$2) : () }
        $self->_send_command("playlistid $song\n");
    # FIXME: return item::songs / item::directory
}

sub searchadd {
    my ($self, $type, $string) = @_;
    my @results = $self->search($type, $string);

    return unless @results;

    my $command =
          "command_list_begin\n"
        . join( '', map { qq[add "$_->{file}"\n] } @results )
        . "command_list_end\n";
    $self->_send_command( $command );
}


sub crop {
    my ($self) = @_;

    my $status = $self->status;
    my $cur = $status->song;
    my $len = $status->playlistlength - 1;

    my $command =
          "command_list_begin\n"
        . join( '', map { $_  != $cur ? "delete $_\n" : '' } 0..$len )
        . "command_list_end\n";
    $self->_send_command( $command );
}


sub playlist {
    my ($self) = @_;

    my @lines = $self->_send_command("playlistinfo\n");

    my @list;
    my %hash;
    foreach my $line (@lines) {
        next unless $line =~ /^([^:]+):\s(.+)$/;
        if ($1 eq 'file') {
            push @list, { %hash } if %hash;
            %hash = ();
        }
        $hash{$1} = $2;
    }
    push @list, { %hash }; # Remember the last entry
    return \@list;
}


sub get_title {
    my ($self, $song) = @_;

    my %data = $self->get_song_info($song);
    return $data{Artist}.' - '.$data{Title} if $data{Artist} && $data{Title};
    return $data{Title} if $data{Title};
    return $data{file};
}

sub get_time_format {
    my ($self) = shift;

    # Get the time from MPD; example: 49:395 (seconds so far:total seconds)
    my ($sofar, $total) = split /:/, $self->status->time;
    return sprintf "%d:%02d/%d:%02d",
        ($sofar / 60), # minutes so far
        ($sofar % 60), # seconds - minutes so far
        ($total / 60), # minutes total
        ($total % 60);# seconds - minutes total
}

sub get_time_info {
    my ($self) = @_;

    # Get the time from MPD; example: 49:395 (seconds so far:total seconds)
    my ($sofar, $total) = split /:/, $self->status->time;
    my $left = $total - $sofar;

    # Store seconds for everything
    my $rv = {};
    $rv->{seconds_so_far} = $sofar;
    $rv->{seconds_total}  = $total;
    $rv->{seconds_left}   = $left;

    # Store the percentage; use one decimal point
    $rv->{percentage} =
    $rv->{seconds_total}
    ? 100*$rv->{seconds_so_far}/$rv->{seconds_total}
    : 0;
    $rv->{percentage} = sprintf "%.1f",$rv->{percentage};


    # Parse the time so far
    my $min_so_far = ($sofar / 60);
    my $sec_so_far = ($sofar % 60);

    $rv->{time_so_far} = sprintf("%d:%02d", $min_so_far, $sec_so_far);
    $rv->{minutes_so_far} = sprintf("%00d", $min_so_far);
    $rv->{seconds_so_far} = sprintf("%00d", $sec_so_far);


    # Parse the total time
    my $min_tot = ($total / 60);
    my $sec_tot = ($total % 60);

    $rv->{time_total} = sprintf("%d:%02d", $min_tot, $sec_tot);
    $rv->{minutes} = $min_tot;
    $rv->{seconds} = $sec_tot;

    # Parse the time left
    my $min_left = ($left / 60);
    my $sec_left = ($left % 60);
    $rv->{time_left} = sprintf("-%d:%02d", $min_left, $sec_left);

    return $rv;
}


sub playlist_changes {
    my ($self, $plid) = @_;

    my %changes;

    my @lines = $self->_send_command("plchanges $plid\n");
    my $entry; # hash reference
    foreach my $line (@lines) {
        next unless $line =~ /^([^:]+):\s(.+)$/;
        my ($key, $value) = ($1, $2);
        # create a new hash for the start of each entry
        $entry = {} if $key eq 'file';
        # save a ref to the entry as soon as we know where it goes
        $changes{$value} = $entry if $key eq 'Pos';
        # save all attributes of the entry
        $entry->{$key} = $value;
    }

    return %changes;
}


1;



__END__

=pod

=head1 NAME

Audio::MPD - Class for talking to MPD (Music Player Daemon) servers


=head1 SYNOPSIS

    use Audio::MPD;

    my $mpd = Audio::MPD->new();
    $mpd->play();
    sleep 10;
    $mpd->next();


=head1 DESCRIPTION

Audio::MPD gives a clear object-oriented interface for talking to and
controlling MPD (Music Player Daemon) servers. A connection to the MPD
server is established as soon as a new Audio::MPD object is created.
Commands are then sent to the server as the class's methods are called.


=head1 METHODS

=head2 Constructor

=over 4

=item new( [[$password@]$host], [$port] )

The C<new()> method is the constructor for the C<Audio::MPD> class.
You may specify a hostname and port - if none is specified then
the enviroment variables C<MPD_HOST> and C<MPD_PORT> are checked.
Finally if all else fails the defaults 'localhost' and '6600' are used.

An optional  password can be specified by prepending it to the
hostname, seperated with an '@' character.

=back


=head2 Controlling the server

=over 4

=item $mpd->ping()

Sends a ping command to the mpd server.


=item $mpd->stats()

Return a hashref with the number of artists, albums, songs in the database,
as well as mpd uptime, the playtime of the playlist / the database and the
last update of the database


=item $mpd->status()

Return a C<Audio::MPD::Status> object with various information on current
MPD server settings. Check the embedded pod for more information on the
available accessors.


=item $mpd->kill()

Send a message to the MPD server telling it to shut down.


=item $mpd->updatedb( [$path] )

Force mpd to recan its collection. If $path (relative to MPD's music directory)
is supplied, MPD will only scan it - otherwise, MPD will rescan its whole
collection.


=item $mpd->send_password( password )

Send a plaintext password to the server,
which can enable optionally password protected functionality.


=item $mpd->get_urlhandlers()

Return an array of supported URL schemes.


=item $mpd->version()

Return the version number for the server we are connected to.

=back


=head2 Changing MPD settings

=over 4

=item $mpd->repeat( [$repeat] )

Set the repeat mode to $repeat (1 or 0). If $repeat is not specified then
the repeat mode is toggled.


=item $mpd->random( [$random] )

Set the random mode to $random (1 or 0). If $random is not specified then
the random mode is toggled.


=item $mpd->fade( [$seconds] )

Enable crossfading and set the duration of crossfade between songs.
If $seconds is not specified or $seconds is 0, then crossfading is disabled.


=item $mpd->volume( [+][-]$volume )

Sets the audio output volume percentage to absolute $volume.
If $volume is prefixed by '+' or '-' then the volume is changed relatively
by that value.


=item $mpd->output_enable( $output )

Enable the specified audio output. $output is the ID of the audio output.


=item $mpd->output_disable( $output )

Disable the specified audio output. $output is the ID of the audio output.

=back


=head2 Controlling playback

=over 4

=item $mpd->play( [$number] )

Begin playing playlist at song number $number.


=item $mpd->playid( [$songid] )

Begin playing playlist at song ID $songid.


=item $mpd->pause( [$state] )

Pause playback. If C<$state> is 0 then the current track is unpaused,
if $state is 1 then the current track is paused.

Note that if C<$state> is not given, pause state will be toggled.


=item $mpd->stop()

Stop playback.


=item $mpd->next()

Play next song in playlist.


=item $mpd->prev()

Play previous song in playlist.


=item $mpd->seek( $time, [$song])

Seek to $time seconds.
If $song number is not specified then the perl module will try and
seek to $time in the current song.


=item $mpd->seekid( $time, $songid )

Seek to $time seconds in song ID $songid.

=back


=head2 Playlist handling

=over 4

=item $mpd->clear()

Remove all the songs from the current playlist. No return value.


=item $mpd->crop()

Remove all of the songs from the current playlist *except* the
song currently playing.


=item $mpd->add( $path )

Add the song identified by $path (relative to MPD's music directory) to the
current playlist. No return value.


=item $mpd->delete( $song )

Remove song number $song from the current playlist.No return value.


=item $mpd->deleteid( $songid )

Remove the specified $songid from the current playlist. No return value.


=item $mpd->swap( $song1, $song2 )

Swap positions of song number $song1 and $song2 on the current playlist. No
return value.


=item $mpd->swapid( $songid1, $songid2 )

Swap the postions of song ID $songid1 with song ID $songid2 on the current
playlist. No return value.


=item $mpd->shuffle()

Shuffle the current playlist. No return value.


=item $mpd->move( $song, $newpos )

Move song number $song to the position $newpos. No return value.


=item $mpd->moveid( $songid, $newpos )

Move song ID $songid to the position $newpos. No return value.


=item $mpd->load( $playlist )

Load list of songs from specified $playlist file. No return value.


=item $mpd->save( $playlist )

Save the current playlist to a file called $playlist in MPD's playlist
directory. No return value.


=item $mpd->rm( $playlist )

Delete playlist named $playlist from MPD's playlist directory. No return value.


=back


=head2 Retrieving information from the collection

=over 4

=item $mpd->search( $type, $string, [$strict] )

Search through MPD's database of music for matching songs.

$type is the field to search in: "title","artist","album", or "filename", and
$string is the keyword(s) to seach for. If $strict is true then only exact
matches are returned.

Return an array of matching file paths.


=item $mpd->searchadd( $type, $string )

Perform the same action as $mpd->search(), but add any
matching songs to the current playlist, instead of just returning
information about them.


=item $mpd->list( $type, [$artist] )

Returns an array of all the "album" or "artist" in
the music database (as chosen by $type). $artist is an
optional parameter, which will only return albums by the
specified $artist when $type is "album".


=item $mpd->listall( [$path] )

Return an array of all the songs in the music database.
If $path is specified, then it only returns songs matching
the directory/path.


=item $mpd->listallinfo( [$path] )

Returns an array of hashes containing all the paths and metadata about
songs in the music database.  If $path is specified, then it only
returns songs matching the directory/path.


=item $mpd->lsinfo( [$directory] )

Returns an array of hashes containing all the paths and metadata about
songs in the specified directory. If no directory is specified, then only
the songs/directories in the root directory are listed.

=back


=head2 Retrieving information from current playlist

=over 4

=item $mpd->get_current_song_info( )

Return a hash of metadata for the song currently playing.


=item $mpd->playlist( )

Return an arrayref containing a hashref of metadata for each of the
songs in the current playlist.


=item $mpd->playlist_changes( $plversion )

Return a hash of hashref with all the differences in the playlist since
playlist $plversion.


=item $mpd->get_song_info( $song )

Returns an a hash containing information about song number $song.


=item $mpd->get_song_info_from_id( $songid )

Returns an a hash containing information about song ID $songid.


=item $mpd->get_title( [$song] )

Return the 'title string' of song number $song. The 'title' is the artist and
title of the song. If the artist isn't available, then just the title is
returned. If there is no title available, then the filename is returned.

If $song is not specified, then the 'title' of the current song is returned.


=item $mpd->get_time_format( )

Returns the current position and duration of the current song.
String is formatted at "M:SS/M:SS", with current time first and total time
after.


=item $mpd->get_time_info( )

Return current timing information in various different formats
contained in a hashref with the following keys:

=over 4

=item minutes_so_far

=item seconds_so_far

=item time_so_far

=item minutes

=item seconds

=item percentage

=item time_total

=item seconds_total

=item seconds_left

=item time_left

=back

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

Original code by Tue Abrahamsen <tue.abrahamsen@gmail.com>, documented by
Nicholas J. Humfrey <njh@aelius.com>.



=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Tue Abrahamsen <tue.abrahamsen@gmail.com>

Copyright (c) 2006 Nicholas J. Humfrey <njh@aelius.com>

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

