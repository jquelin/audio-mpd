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

use IO::Socket;

use warnings;
use strict;

our $VERSION = '0.12.3';



###############################################################
#                        CONFIGURATION                        #
#-------------------------------------------------------------#
#   Only holds the hash specifying different configuration-   #
#  values used by the module. These may not be changed during #
#   runtime, but can be altered for the programmers wishes.   #
###############################################################

my %config = (
    # Overwrites old playlist, if a playlist is saved with the same
    # name. Otherwise, an error is returned. Default: yes
    OVERWRITE_PLAYLIST => 1,
    # Allows toggling repeat and random states by not specifying
    # parameteres. Default: yes
    ALLOW_TOGGLE_STATES => 1,
    # The default host to connect to, if no other host is specified.
    DEFAULT_MPD_HOST => 'localhost',
    # The default port to connect to, if no other port is specified.
    DEFAULT_MPD_PORT => 6600,
);


###############################################################
#                       BASIC METHODS                         #
#-------------------------------------------------------------#
#  This section contains all basic methods for the module to  #
#     function, internal methods and methods not returning    #
#      or altering information about playback and alike.      #
###############################################################



#
# my $mpd = Audio::MPD->new( [[$password@]$hostname], [$port] )
#
# This is the constructor for Audio::MPD. One can specify a $hostname and a
# $port - if none is specified then defaults to environment vars MPD_HOST and
# MPD_PORt. If those aren't set, defaults to 'localhost', 6600.
#
# An optional $password can be specified by prepending it to $hostname,
# seperated with an '@' character.
#
sub new
{
    my $class = shift;
    my($mpd_host,$mpd_port) = @_;

    my $self = {
        # Version of MPD server
        server_version => undef,
        password => undef,
        # Variables for ACK error
        ack_error_id => undef,
        ack_error_command_id => undef,
        ack_error_command => undef,
        ack_error => undef,
        # MPD connection information
        mpd_host => $mpd_host || $ENV{MPD_HOST} || $config{DEFAULT_MPD_HOST},
        mpd_port => $mpd_port || $ENV{MPD_PORT} || $config{DEFAULT_MPD_PORT},
        # Socket handle
        sock => undef,
        # Array holding playlist-entries in hashes
        playlistref => [],
        # Variables set by command 'status'
        volume => undef,
        repeat => undef,
        random => undef,
        state => undef,
        playlist => -1,
        playlistlength => undef,
        bitrate => undef,
        xfade => undef,
        audio => undef,
        error => undef,
        song => undef,
        time => undef,
        # Variables set by command 'stats'
        artists => undef,
        albums => undef,
        songs => undef,
        uptime => undef,
        db_playtime => undef,
        db_update => undef,
        playtime => undef,
        # 0.12.0 stuff
        outputs => undef,
        commands => undef,
        notcommands => undef,
    };
    bless($self,$class);

    # Check for password in host name
    if($self->{mpd_host} =~ /@/)
    {
        ($self->{password},$self->{mpd_host}) = split('@',$self->{mpd_host});
    }

    $self->_connect;
    $self->send_password if $self->{password};
    return $self;
}

sub is_connected
{
    my($self) = shift;
    # No need to check, if socket has not been initialized
    if($self->{sock})
    {
        $self->{sock}->print("ping\n");
        if($self->{sock}->getline() =~ /^OK/)
        {
            return 1;
        } else {
            return undef;
        }
    }
    return undef;
}

sub close_connection
{
    my($self) = shift;
    $self->_disconnect();
    return 1;
}

sub kill_mpd
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("kill\n");
    return 1;
}

sub send_password
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("password ".$self->{password}."\n");
    $self->_process_feedback;
    return 1;
}

sub get_urlhandlers
{
    my($self) = shift;
    $self->_connect;
    my @handlers;
    $self->{sock}->print("urlhandlers\n");
    foreach($self->_process_feedback)
    {
        push(@handlers, $1) if /^handler: (.+)$/;
    }
    return @handlers;
}

sub get_error
{
    my($self) = shift;
    return (                            # Let's return an array
        $self->{ack_error_id},          # [0] What is the ID of the error?
        $self->{ack_error},             # [1] Human readable error-message
        $self->{ack_error_command},     # [2] The command that caused the error
        $self->{ack_error_command_id}   # [3] What number the command was in the command_list (if used)
    );
}

sub get_server_version
{
    my($self) = shift;
    return $self->{server_version};
}


###############################################################
#               METHODS FOR ALTERING SETTINGS                 #
#-------------------------------------------------------------#
#  This section contains methods used for altering different  #
#                     settings in MPD.                        #
###############################################################

sub set_repeat
{
    my($self,$mode) = @_;
    $self->_connect;

    # If the mode is not set, and ALLOW_TOGGLE_STATUS is, return false!
    return undef if((!defined($mode) && !$config{'ALLOW_TOGGLE_STATUS'}) || $mode !~ /^(0|1)$/);

    # If mode is not set, shift the current status
    $mode = ($self->{repeat} == 1 ? 0 : 1) if !defined($mode);

    $self->{sock}->print("repeat $mode\n");
    $self->{repeat} = $mode;
    return $self->_process_feedback;
}

sub set_random
{
    my($self,$mode) = @_;
    $self->_connect;

    # If the mode is not set, and ALLOW_TOGGLE_STATUS is, return false!
    return undef if((!defined($mode) && !$config{'ALLOW_TOGGLE_STATUS'}) || $mode !~ /^(0|1)$/);

    # If mode is not set, shift the current status
    $mode = ($self->{random} == 1 ? 0 : 1) if !defined($mode);

    $self->{sock}->print("random $mode\n");
    $self->{random} = $mode;
    return $self->_process_feedback;
}

sub set_fade
{
    my($self,$fade_value) = @_;
    $self->_connect;
    $fade_value = 0 if !defined($fade_value);
    $self->{sock}->print("crossfade $fade_value\n");
    $self->{xfade} = $fade_value;
    return $self->_process_feedback;
}

sub set_volume
{
    my($self,$volume) = @_;
    $self->_connect;

    if($volume =~ /^(-|\+)(\d+)/ && defined($self->{volume}))
    {
        $volume = $self->{volume} + $2 if $1 eq '+';
        $volume = $self->{volume} - $2 if $1 eq '-';
    }

    return undef if !defined($volume) || $volume < 0 || $volume > 100;

    $self->{sock}->print("setvol $volume\n");
    $self->{volume} = $volume;
    return $self->_process_feedback;
}

sub output_enable
{
    my($self,$output) = @_;
    $self->_connect;
    return undef if(!defined($output) || $output !~ /^\d+$/);
    $self->{sock}->print("enableoutput $output\n");
    my @tmp = $self->_process_feedback;
    $self->_get_outputs;
    return @tmp;
}

sub output_disable
{
    my($self,$output) = @_;
    $self->_connect;
    return undef if(!defined($output) || $output !~ /^\d+$/);
    $self->{sock}->print("disableoutput $output\n");
    my @tmp = $self->_process_feedback;
    $self->_get_outputs;
    return @tmp;
}

###############################################################
#                METHODS FOR COMMON PLAYBACK                  #
#-------------------------------------------------------------#
#   This section contains the most commonly used methods for  #
#                    altering playback.                       #
###############################################################

sub play
{
    my($self,$number,$from_id) = @_;
    $self->_connect;
    $number = '' if !defined($number);
    my $command = (defined($from_id) && $from_id == 1 ? 'playid' : 'play');
    $self->{sock}->print("$command $number\n");
    return $self->_process_feedback;
}

sub playid
{
    my($self,$number) = @_;
    $number = '' if !defined($number);
    return $self->play($number,1);
}

sub pause
{
    my($self,$state) = @_;

    # Default is to pause
    $state = 1 unless (defined $state);

    $self->_connect;
    $self->{sock}->print("pause $state\n");
    return $self->_process_feedback;
}

sub stop
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("stop\n");
    return $self->_process_feedback;
}

sub next
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("next\n");
    return $self->_process_feedback;
}

sub prev
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("previous\n");
    return $self->_process_feedback;
}

sub seek
{
    my($self,$position,$song,$from_id) = @_;
    $self->_connect;
    my $command = (defined($from_id) && $from_id == 1 ? 'seekid' : 'seek');
    $position = int($position) if(defined($position)); # Go INT!
    if(defined($song) && defined($position) && $song =~ /^\d+$/ && $position =~ /^\d+$/)
    {
        $self->{sock}->print("$command $song $position\n");
    } elsif(defined($position) && $position =~ /^\d+$/ && defined($self->{song})) {
        $self->{sock}->print("$command ".$self->{song}." $position\n");
    } else {
        return undef;
    }
    return $self->_process_feedback;
}

sub seekid
{
    my($self,$position,$songid) = @_;
    return undef if !defined($position) || !defined($songid);
    return $self->seek($position,$songid,1);
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
sub clear
{
    my ($self) = shift;
    $self->_connect;
    $self->{sock}->print("clear\n");
    return $self->_process_feedback;
}



sub add
{
    my($self,$path) = @_;
    $self->_connect;
    $path = '' if !defined($path);
    $self->{sock}->print("add \"$path\"\n");
    return $self->_process_feedback;
}

sub delete
{
    my($self,$song,$from_id) = @_;
    $self->_connect;
    return undef if !defined($song);
    my $command = (defined($from_id) && $from_id == 1 ? 'deleteid' : 'delete');
    if($song =~ /^(\d+)-(\d+)$/)
    {
        for(my $i = $2 ; $i >= $1 ; $i--)
        {
            $self->$command($i);
        }
    } else {
        $self->{sock}->print("$command $song\n");
        return $self->_process_feedback;
    }
    return 1;
}

sub deleteid
{
    my($self,$songid) = @_;
    return undef if !defined($songid) || $songid !~ /^\d+$/;
    return $self->delete($songid,1);
}

sub load
{
    my($self,$playlist) = @_;
    return undef if !defined($playlist);
    $self->_connect;
    $self->{sock}->print("load \"$playlist\"\n");
    return $self->_process_feedback;
}

sub updatedb
{
    my($self, $path) = shift;

    $path = '' unless (defined $path);

    $self->_connect;
    $self->{sock}->print("update $path\n");
    return $self->_process_feedback;
}

sub swap
{
    my($self,$song_from,$song_to,$from_id) = @_;
    $self->_connect;
    if(defined($song_from) && defined($song_to) && $song_from =~ /^\d+$/ && $song_to =~ /^\d+$/)
    {
        my $command = (defined($from_id) && $from_id == 1 ? 'swapid' : 'swap');
        $self->{sock}->print("$command $song_from $song_to\n");
    } else {
        return undef;
    }
    return $self->_process_feedback;
}

sub swapid
{
    my($self,$songid_from,$songid_to) = @_;
    return undef if !defined($songid_from) || !defined($songid_to) || $songid_from !~ /^\d+$/ || $songid_to !~ /^\d+$/;
    return $self->swap($songid_from,$songid_to,1);
}

sub shuffle
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("shuffle\n");
    return $self->_process_feedback;
}

sub move
{
    my($self,$song,$new_pos,$from_id) = @_;
    $self->_connect;
    if(defined($song) && defined($new_pos) && $song =~ /^\d+$/ && $new_pos =~ /^\d+$/)
    {
        my $command = (defined($from_id) && $from_id == 1 ? 'moveid' : 'move');
        $self->{sock}->print("$command $song $new_pos\n");
    } else {
        return undef;
    }
    return $self->_process_feedback;
}

sub moveid
{
    my($self,$songid,$new_pos) = @_;
    return undef if !defined($songid) || !defined($new_pos) || $songid !~ /^\d+$/ || $new_pos !~ /^\d+$/;
    return $self->move($songid,$new_pos,1);
}

sub rm
{
    my($self,$playlist) = @_;
    return undef if !defined($playlist);
    $self->_connect;
    $self->{sock}->print("rm \"$playlist\"\n");
    return $self->_process_feedback;
}

sub save
{
    my($self,$playlist) = @_;
    return undef if !defined($playlist);
    $self->_connect;
    $self->{sock}->print("save \"$playlist\"\n");
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
}

sub search
{
    my($self,$type,$string,$strict) = @_;
    return undef if !defined($type) || !defined($string) || $type !~ /^(artist|album|title|filename)$/;
    $self->_connect;
    my $command = (!defined($strict) || $strict == 0 ? 'search' : 'find');
    $self->{sock}->print("$command $type \"$string\"\n");

    my @list;
    my %hash;
    foreach($self->_process_feedback)
    {
        if(/^(.[^:]+):\s(.+)$/)
        {
            if($1 eq 'file')
            {
                push @list, { %hash } if %hash;
                %hash = ();
            }
            $hash{$1} = $2;
        }
    }
    push @list, { %hash } if %hash; # Remember the last entry
    return @list;
}

sub list
{
    my($self,$type,$artist) = @_;
    return undef if !defined($type) || $type !~ /^(artist|album)$/;
    $self->_connect;
    $artist = '' if !defined($artist);
    print $self->{sock} ($type eq 'album' ? "list album \"$artist\"\n" : "list artist\n");

    #   Strip unneccesary information
    my @tmp;
    foreach($self->_process_feedback)
    {
        push @tmp, $1 if /^(?:Artist|Album):\s(.+)$/;
    }
    return @tmp;
}

sub listall
{
    my($self,$path) = @_;
    $self->_connect;
    $path = '' if !defined($path);
    $self->{sock}->print("listall \"$path\"\n");
    return $self->_process_feedback;
}

sub listallinfo
{
    my($self,$path) = @_;
    $self->_connect;
    $path = '' if !defined($path);
    $self->{sock}->print("listallinfo \"$path\"\n");
    my @results;
    my %element;
    foreach($self->_process_feedback)
    {
        if(/^(.[^:]+):\s(.+)$/)
        {
            if($1 eq 'file')
            {
                push @results, { %element } if %element;
                %element = ();
            }
            $element{$1} = $2
        }
    }
    push @results, { %element } if %element;
    return @results;
}

sub lsinfo
{
    my($self,$path) = @_;
    $self->_connect;
    $path = '' if !defined($path);
    $self->{sock}->print("lsinfo \"$path\"\n");
    my @results;
    my %element;
    foreach($self->_process_feedback)
    {
        if(/^(.[^:]+):\s(.+)$/)
        {
            #if($1 =~ /^(?:file|playlist|directory)$/)
            if($1 eq 'file' || $1 eq 'playlist' || $1 eq 'directory')
            {
                push @results, { %element } if %element;
                %element = ();
            }
            $element{$1} = $2;
        }
    }
    push @results, { %element } if %element;
    return @results;
}

###############################################################
#                     CUSTOM METHODS                          #
#-------------------------------------------------------------#
#   This section contains all methods not directly accessing  #
#   MPD, but may be useful for most people using the module.  #
###############################################################

sub get_song_info
{
    my($self,$song,$from_id) = @_;
    if(!defined($song)) {
        $self->_connect;
        $self->_get_status;
        $song = $self->{song};
    }
    $self->{sock}->print("playlist".(defined($from_id) && $from_id == 1 ? 'id' : 'info')." $song\n");
    my %metadata;
    foreach($self->_process_feedback)
    {
        $metadata{$1} = $2 if /^(.[^:]+):\s(.+)$/;
    }
    return %metadata;
}

sub get_current_song_info
{
    my($self) = @_;
    $self->{sock}->print("currentsong\n");
    my %metadata;
    foreach($self->_process_feedback)
    {
        $metadata{$1} = $2 if /^(.[^:]+):\s(.+)$/;
    }
    return %metadata;
}

sub get_song_info_from_id
{
    my($self,$song) = @_;
    # No reason to write it all again :)
    $self->get_song_info($song,1);
}

sub searchadd
{
    my($self,$type,$string) = @_;
    return undef if !defined($type) || !defined($string);
    $self->_connect;
    my @results = $self->search($type, $string);
    if($#results > -1)
    {
        $self->{sock}->print("command_list_begin\n");
        foreach(@results)
        {
            my %hash = %$_;
            $self->{sock}->print("add \"".$hash{'file'}."\"\n");
        }
        $self->{sock}->print("command_list_end\n");
        if($self->_process_feedback)
        {
            $self->{playlist} = $self->{playlist} + $#results + 1;
        }
    }
    return 1;
}


sub crop
{
    my($self) = shift;
    $self->{sock}->print("command_list_begin\n");
    for(my $i = ($self->{playlistlength}-1) ; $i >= ($self->{song}+1) ; $i--)
    {
        $self->{sock}->print("delete $i\n");
    }
    for(my $i = ($self->{song}-1) ; $i >= 0 ; $i--)
    {
        $self->{sock}->print("delete $i\n");
    }
    $self->{sock}->print("command_list_end\n");
    $self->_process_feedback;
}


sub playlist
{
    my($self) = shift;
    $self->_connect;
    $self->_get_playlist if !defined($self->{playlistref}->[0]);
    return $self->{playlistref};
}

sub get_title
{
    my($self,$song) = @_;
    my %metadata;
    if(defined($song)) {
        $self->_connect;
        $self->_get_status;
        my $info;
        $info = $self->{song} unless !defined($self->{song}) || $self->{song} =~ /^\D+$/;
        $info = $song unless $song =~ /^\D+$/;
        return 'n/a' if !defined($info);
        return '' if !defined($self->{playlistlength}) || $info eq 'false' || ($info ne 'false' && $self->{playlistlength}-1 < $info);
        %metadata = $self->get_song_info($info);
    } else {
        %metadata = $self->get_current_song_info();
    }
    return $metadata{'Artist'}.' - '.$metadata{'Title'} if $metadata{'Artist'} && $metadata{'Title'};
    return $metadata{'Title'} if $metadata{'Title'};
    return $metadata{'file'};
}

sub get_time_format
{
    my($self) = shift;

    $self->_get_status;
    return '' if !defined($self->{playlistlength}) || !defined($self->{song});

    #Get the time from MPD; example: 49:395 (seconds so far:total seconds)
    my($psf,$tst) = split /:/, $self->{'time'};
    return sprintf("%d:%02d/%d:%02d",
        ($psf / 60), # minutes so far
        ($psf % 60), # seconds - minutes so far
        ($tst / 60), # minutes total
        ($tst % 60));# seconds - minutes total
}

sub get_time_info
{
    my ($self) = shift;

    return '' if !defined($self->{playlistlength}) || !defined($self->{song});

    #The return variable
    my $rv = {};

    #Get the time from MPD; example: 49:395 (seconds so far:total seconds)
    $self->_get_status;
    my($so_far,$total) = split(/:/, $self->{'time'});
    my $left = $total-$so_far;

    #Store seconds for everything
    $rv->{seconds_so_far} = $so_far;
    $rv->{seconds_total}  = $total;
    $rv->{seconds_left}   = $left;

    #Store the percentage; use one decimal point
    $rv->{percentage} =
    $rv->{seconds_total}
    ? 100*$rv->{seconds_so_far}/$rv->{seconds_total}
    : 0;
    $rv->{percentage} = sprintf("%.1f",$rv->{percentage});


    #Parse the time so far
    my $min_so_far = ($so_far / 60);
    my $sec_so_far = ($so_far % 60);

    $rv->{time_so_far} = sprintf("%d:%02d", $min_so_far, $sec_so_far);
    $rv->{minutes_so_far} = sprintf("%00d", $min_so_far);
    $rv->{seconds_so_far} = sprintf("%00d", $sec_so_far);


    #Parse the total time
    my $min_tot = ($total / 60);
    my $sec_tot = ($total % 60);

    $rv->{time_total} = sprintf("%d:%02d", $min_tot, $sec_tot);
    $rv->{minutes} = $min_tot;
    $rv->{seconds} = $sec_tot;

    #Parse the time left
    my $min_left = ($left / 60);
    my $sec_left = ($left % 60);
    $rv->{time_left} = sprintf("-%d:%02d", $min_left, $sec_left);

    return $rv;
}

sub playlist_changes
{
    my($self,$old_playlist_id) = @_;
    $old_playlist_id = -1 if !defined($old_playlist_id);
    my %changeset;

    $self->_connect;
    $self->{sock}->print("plchanges $old_playlist_id\n");
    my $changedEntry; # hash reference
    foreach($self->_process_feedback)
    {
        if(/^(.[^:]+):\s(.+)$/)
        {
            my($key, $value) = ($1, $2);
            # create a new hash for the start of each entry
            $changedEntry = {} if($key eq 'file');
            # save a ref to the entry as soon as we know where it goes
            $changeset{$value} = $changedEntry if $key eq 'Pos';
            # save all attributes of the entry
            $changedEntry->{$key} = $value;
        }
    }

    return %changeset;
}



#-------------------------------------------#
#             INTERNAL METHODS              #
#-------------------------------------------#
# This sub-section is only used for methods #
# not meant to be accessed from the outside.#
#-------------------------------------------#

sub _connect
{
    my($self) = shift;
    return 1 if $self->is_connected;
    $self->{sock} = new IO::Socket::INET
    (
        PeerAddr => $self->{mpd_host},
        PeerPort => $self->{mpd_port},
        Proto => 'tcp',
    );
    die("Could not create socket: $!\n") unless $self->{sock};

    if($self->{sock}->getline() =~ /^OK MPD (.+)$/)
    {
        $self->{sever_version} = $1;
    } else {
        die("Could not connect: $!\n");
    }
    $self->send_password if $self->{password};
    $self->_get_status;
    $self->_get_outputs;
    $self->_get_commands;
    return 1;
}

sub _disconnect
{
    my($self) = shift;

    if ($self->{sock}) {
        $self->{sock}->print("close\n") ;
        $self->{sock}->close();
    }
}

sub _process_feedback
{
    my($self) = shift;
    my @output;
    while(my $line = $self->{sock}->getline())
    {
        chomp($line);

        # Did we cause an error? Save the data!
        if($line =~ /^ACK \[(\d+)\@(\d+)\] {(.*)} (.+)$/)
        {
            $self->{ack_error_id} = $1;
            $self->{ack_error_command_id} = $2;
            $self->{ack_error_command} = $3;
            $self->{ack_error} = $4;
            return undef;
        }

        last if ($line =~ /^OK/);
        push(@output, $line);
    }

    # Let's return the output for post-processing
    return @output;
}

sub _get_status
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("status\n");
    foreach($self->_process_feedback)
    {
        if(/^(.[^:]+):\s(.+)$/) {
            $self->{$1} = $2;
        }
    }
    return 1;
}

sub _get_stats
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("stats\n");
    foreach($self->_process_feedback)
    {
        $self->{$1} = $2 if /^(.[^:]+):\s(.+)$/;
    }
    return 1;
}

sub _get_playlist
{
    my($self,$old_playlist_id) = @_;
    $self->_connect;
    my %changes = $self->playlist_changes($old_playlist_id);
    for my $pos (keys %changes)
    {
        $self->{playlistref}->[$pos] = $changes{$pos};
    }

    # Deletes songs no longer in the playlist
    while($#{$self->{playlistref}} > $self->{playlistlength} - 1) {
        pop @{$self->{playlistref}};
    }

    return 1;
}

sub _get_outputs
{
    my($self) = shift;
    $self->_connect;
    $self->{sock}->print("outputs\n");
    my @outputs;
    my %output;
    foreach($self->_process_feedback)
    {
        next if !defined;
        if(/^outputid:/)
        {
            push @outputs, { %output } if %output;
            %output = ();
        }
        $output{$1} = $2 if /^output(.+): (.+)$/;
    }
    push @outputs, { %output } if %output;
    $self->{outputs} = \@outputs;
    return 1;
}

sub _get_commands
{
    my($self) = shift;
    $self->_connect;
    my(@commands,@notcommands);
    $self->{sock}->print("commands\n");
    foreach($self->_process_feedback)
    {
        next if !defined;
        push @commands, $1 if /^command: (.+)$/;
    }
    $self->{sock}->print("notcommands\n");
    foreach($self->_process_feedback)
    {
        next if !defined;
        push @notcommands, $1 if /^command: (.+)$/;
    }
    $self->{commands} = \@commands;
    $self->{notcommands} = \@notcommands;
    return 1;
}


sub DESTROY
{
    my($self) = shift;

    $self->_disconnect();
}

#-------------------------------------------#
#           INTERNAL METHODS - END          #
#-------------------------------------------#

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

=item $mpd->is_connected()

Check to see if there is a valid connection to the MPD server.
First check that the socket is connected and then send a Ping command
check that the replyis 'OK'. Return '1' if connected and undef if not.


=item $mpd->close_connection()

Close the connection to the MPD server.


=item $mpd->kill_mpd()

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


=item $mpd->get_error()

Return an array containing information about the last error that occured.

 - Item 0: The ID number of the error
 - Item 1: Human readable error message
 - Item 2: The command that caused the error
 - Item 3: The position in the command_list of the command (if used)


=item $mpd->get_server_version()

Return the version number for the server we are connected to.

=back


=head2 Changing MPD settings

=over 4

=item $mpd->set_repeat( [$repeat] )

Set the repeat mode to $repeat (1 or 0). If $repeat is not specified then
the repeat mode is toggled.


=item $mpd->set_random( [$random] )

Set the random mode to $random (1 or 0). If $random is not specified then
the random mode is toggled.


=item $mpd->set_fade( [$seconds] )

Enable crossfading and set the duration of crossfade between songs.
If $seconds is not specified or $seconds is 0, then crossfading is disabled.


=item $mpd->set_volume( [+][-]$volume )

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

=item $mpd->play( [$number], [$fromid] )

Begin playing playlist at song number $number.
If $fromid is true then begin playing at song with ID $number.


=item $mpd->playid( [$songid] )

Begin playing playlist at song ID $songid.


=item $mpd->pause( [$state] )

Pause playback. If $state is 0 then the current track is unpaused,
if $state is 1 then the current track is paused.


=item $mpd->stop()

Stop playback.


=item $mpd->next()

Play next song in playlist.


=item $mpd->prev()

Play previous song in playlist.


=item $mpd->seek( $position, [$song], [$fromid] )

Seek to $position seconds.
If $song number is not specified then the perl module will try and
seek to $position in the current song. If $fromid is true then
$song is the ID of the song to seek in.


=item $mpd->seekid( $position, $songid )

Seek to $position seconds in song ID $songid.

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


=item $mpd->delete( $song, [$fromid] )

Remove song number $song from the current playlist. If $fromid is true, then
$song is the ID of the song to be removed. No return value.


=item $mpd->deleteid( $songid )

Remove the specified $songid from the current playlist. No return value.


=item $mpd->swap( $song1, $song2, [$fromid] )

Swap positions of song number $song1 and $song2 on the current playlist. If
$fromid is true, then $song1 and $song are the IDs of the songs. No return
value.


=item $mpd->swapid( $songid1, $songid2 )

Swap the postions of song ID $songid1 with song ID $songid2 on the current
playlist. No return value.


=item $mpd->shuffle()

Shuffle the current playlist. No return value.


=item $mpd->move( $song, $newpos, [$fromid] )

Move song number $song to the position $newpos. If $fromid is true, then $song
is the ID of the song. No return value.


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


=item $mpd->get_song_info( $song, $fromid )

Returns an a hash containing information about song number $song.
If $fromid is true, then $song is the ID of the song.


=item $mpd->get_song_info_from_id( $songid )

Returns an a hash containing information about song ID $songid.


=item $mpd->get_title( [$song] )

Return the 'title string' of song number $song. The 'title' is the artist and
title of the song. If the artist isn't available, then just the title is
returned. If there is no title available, then the filename is returned.

If $song is not specified, then the 'title' of the current song is returned.


=item $mpd->get_time_format( [$song] )

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

Written by:

=over 4

=item *

Tue Abrahamsen <tue.abrahamsen@gmail.com>

=item *

Jerome Quelin <jquelin@cpan.org>

=back


Documented by:

=over 4

=item *

Nicholas J. Humfrey <njh@aelius.com>

=item *

Jerome Quelin <jquelin@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Tue Abrahamsen

Copyright (c) 2006 Nicholas J. Humfrey

Copyright (c) 2007 Jerome Quelin


This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut

