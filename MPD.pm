#!/usr/bin/perl -w
#
# MPD perl module
# Copyright (C) 2004 Tue Abrahamsen (twoface@wtf.dk)
# This project's homepage is: http://code.growl.dk/mpd
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
# Changelog:
#
# 0.1 - Initial release
#
package MPD;
use strict;
use IO::Socket;

my $sock;
my @playlist;

#-------------------------------------------------------------#
#                       BASIC SUBS                            #
#-------------------------------------------------------------#

=item MPD->new ()

The constructor.

Returns reference to self.

=cut
sub new
{
    my $self = {
        # Variables set by class
        version => undef,
        connected => undef,
        # Variables set by command 'status'
        volume => undef,
        repeat => undef,
        random => undef,
        state => undef,
        playlist => undef,
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
        };
    bless($self);
    return $self;
}

=item $foo->connect ([$host, [$port]])

Connects to MPD server at either specified - , enviroment variables - , og preset host:port.

Returns nothing, but dies on failed connection.

=cut
sub connect
{
    my($self,$host,$port) = @_;
    $sock = new IO::Socket::INET
    (
        PeerAddr => $host || $ENV{'MPD_HOST'} || 'localhost',
        PeerPort => $port || $ENV{'MPD_PORT'} || 2100,
        Proto => 'tcp',
    );
    die("Could not create socket: $!\n") unless $sock;
    while(<$sock>)
    {
        if($_ =~ /^OK MPD (.+)$/)
        {
            $self->{version} = $1;
            $self->{connected} = 1;
            last;
        } else {
            die("Could not connect: $!\n");
        }
    }
    &getstats;
    &getstatus;
    &getplaylist;
    return;
}

=item $foo->getstatus

Reads server-status into module variables.

Returns nothing.

=cut
sub getstatus
{
    my($self) = @_;
    print $sock "status\n";
    while(<$sock>)
    {
        chomp;
        last if $_ eq 'OK';
        $self->{$1} = $2 if $_ =~ /^(.+):\s(.+)$/;
    }
    return;
}

=item $foo->getstatus

Reads serverstats into module variables.
    
Returns nothing.
    
=cut
sub getstats
{
    my($self) = @_;
    print $sock "status\n";
    while(<$sock>)
    {
        chomp;
        last if $_ eq 'OK';
        $self->{$1} = $2 if $_ =~ /^(.+):\s(.+)$/;
    }   
    return;
}

=item $foo->getplaylist ()

Internal function for reading entire playlist into @playlist.

Returns nothing on success, but error on error.

=cut
sub getplaylist
{
    my($self) = @_;
    print $sock "playlistinfo\n";
    
    my @tmp;
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^file:/)
        {
            push @playlist, [@tmp] if @tmp;
            @tmp = $_;
        } else {
            push @tmp, $_;
        }
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->gettitle ([$song])

Returns title of $song if specified, otherwise playing song.
Title is made of id3-tag-information if available, otherwise filename.

=cut
sub gettitle
{
    my($self,$song) = @_;
    my($artist, $title);
    
    &getstatus if $song;
    my $info = $song || $self->{song};
    #print $playlist[$info][0];
    $artist = $playlist[$info][0];
    for(my $i = 0; $i<@{$playlist[$info]} ; $i++)
    {
        $artist = $1 if $playlist[$info][$i] =~ /^Artist:\s(.+)$/;
        $title = $1 if $playlist[$info][$i] =~ /^Title:\s(.+)$/;
    }
    return "$artist - $title" if $artist && $title;
    return $artist;
}

=item $foo->gettimeformat
Written by decius (jesper@noehr.org)

Returns formatted time of currently playing song.

=cut
sub gettimeformat
{
    my($self) = @_;
    &getstatus;
    my($psf,$tst) = split /:/, $self->{'time'};
    return sprintf("%d:%02d/%d:%02d",
           ($psf / 60), # minutes so far
           ($psf % 60), # seconds - minutes so far
           ($tst / 60), # minutes total
           ($tst % 60));# seconds - minutes total
}

=item $foo->clearerror ()

Clears current error.

Returns nothing on success, but error on error.

=cut
sub clearerror
{
    my($self) = @_;
    print $sock "clearerror\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item sub->close ()

Closes current connection to MPD.

Returns nothing.

=cut
sub close
{
    my($self) = @_;
    print $sock "close\n";
    return;
}

=item $foo->kill ()

Kills MPD.

Returns nothing.

=cut
sub kill
{
    my($self) = @_;
    print $sock "kill\n";
    return;
}

=item $foo->ping ()

Returns OK if connection is established to MPD.

=cut
sub ping
{
    my($self) = @_;
    print $sock "ping\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^OK/;
    }
}

#-------------------------------------------------------------#
#               SUBS FOR ALTERING SETTINGS                    #
#-------------------------------------------------------------#

=item $foo->setrepeat ([$status])

Sets 'repeat'-status to $status if specified. If not, status is shifted. $status must be 0, 1, on or off.

Returns nothing on success, but error on error.

=cut
sub setrepeat
{
    my($self,$status) = @_;
    my $command;
    $status =~ s/off/0/ if $status;
    $status =~ s/on/1/ if $status; 
    $status = $status if $status && $status =~ /^(0|1)$/;
    $status = ($self->{repeat} == 1 ? 0 : 1) if !$status;
    $command = "repeat $status\n";
    print $sock $command;
    $self->{repeat} = $status;
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->setrandom ([$status])

Sets 'random'-status to $status if specified. If not, status is shifted. $status must be 0, 1, on or off.

Returns nothing on success, but error on error.
    
=cut
sub setrandom
{
    my($self,$status) = @_;
    my $command;
    $status =~ s/off/0/ if $status;
    $status =~ s/on/1/ if $status;
    $status = $status if $status && $status =~ /^(0|1)$/;
    $status = ($self->{random} == 1 ? 0 : 1) if !$status;
    $command = "random $status\n";
    print $sock $command;
    $self->{random} = $status;
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->setfade ($secs)

Sets crossfading to $secs seconds.

Returns nothing on success, but error on error.

=cut
sub setfade
{
    my($self,$secs) = @_;
    print $sock "crossfade $secs\n";
    $self->{xfade} = $secs;
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->setvolume ($volume)

Sets volume to $volume, if $volume is an integer between 0 and 100.
Sets volume to current volume +/- if $volume consists of a + or - and a integer. (setvolume('-25') turns down volume 25)

Returns nothing on success, but error on error.

=cut
sub setvolume
{
    my($self,$volume) = @_;
    
    if($volume =~ /^(-|\+)/ && $self->{volume})
    {
        $volume = $self->{volume} + $1 if $volume =~ /^\+(\w+)$/; 
        $volume = $self->{volume} - $1 if $volume =~ /^-(\w+)$/;
    }
    if($volume && $volume =~ /^(1\w{2}|\w{2})$/)
    {
        print $sock "setvol $volume\n";
    } else {
        return "Must be setvolume(int)";
    }
    $self->{volume} = $volume;
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

#-------------------------------------------------------------#
#                  SUBS FOR COMMON PLAYBACK                   #
#-------------------------------------------------------------#

=item $foo->play ([$song])

Starts playback. Plays $song if specified.

Returns nothing on success, buts error on error.

=cut
sub play 
{
    my($self,$number) = @_;
    $number--;
    print $sock "play $number\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->pause

Pauses playback, but resumes from pause if already paused.

Returns nothing on success, but error on error.

=cut
sub pause
{
    my($self) = @_;
    print $sock "pause\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->stop ()

Stops playback.

Returns nothing on success, but error on error.

=cut
sub stop
{
    my($self) = @_;
    print $sock "stop\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->next ()

Plays next song in playlist.

Returns nothing on success, but error on error.

=cut
sub next
{
    my($self) = @_;
    print $sock "next\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    } 
}

=item $foo->prev ()

Plays previous song in playlist.

Returns nothing on success, but error on error.

=cut
sub prev
{
    my($self) = @_;
    print $sock "previous\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->setpause ([$toggle])

Toggles pausemode. Pauses if playing, plays if paused. Sets pause to $toggle if set. $toggle must be 0 or 1.

Returns nothing on success, but error on error.

=cut
sub setpause
{
    my($self,$toggle) = @_;
    print $sock "pause $toggle\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->seek ($song, $time)

Seeks to position $time (in seconds) in song $song.

Returns nothing on success, but error on error.

=cut
sub seek
{
    my($self,$song,$time) = @_;
    if($song && $time && $song =~ /^\w+$/ && $time =~ /^\w+$/)
    {
        print $sock "seek $song $time\n";
    } else {
        return "Must be seek(int, int)";
    }
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

#-------------------------------------------------------------#
#                 SUBS FOR PLAYLIST-HANDLING                  #
#-------------------------------------------------------------#

=item $foo->clear ()

Clears current playlist.

Returns nothing on success, but error on error.

=cut
sub clear
{
    my($self) = @_;
    print $sock "clear\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->add ($path)

Adds $path to playlist. $path must be file or directory currently in database.

Returns nothing on succes, but error on error.

=cut
sub add
{
    my($self,$path) = @_;
    print $sock "add $path\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->delete ($song)

Deletes $song from playlist. $song must a integer describing the entry in the playlist.

Returns nothing on success, but error on error.

=cut
sub delete
{
    my($self,$song) = @_;
    print $sock "delete $song\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
} 

=item $foo->load ($list)

Loads $list playlist from the playlist directory.

Returns nothing on succes, but error on error.

=cut
sub load
{
    my($self,$list) = @_;
    print $sock "load $list\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->update ()

Searches music directory for new music, and removes old music from the database.

Returns nothing on success, but error on error.

=cut
sub update
{
    my($self) = @_;
    print $sock "update\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->swap ($foo, $bar)

Swaps $foo and $bar in playlist. $foo and $bar must be integers.

Returns nothing on success, but error on error.

=cut
sub swap
{
    my($self,$foo,$bar) = @_;
    if($foo && $bar && $foo =~ /\w+/ && $bar =~ /\w+/)
    {
        print $sock "swap $foo $bar\n";
    } else {
        return "Must be 'swap(int, int)'";
    }
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->shuffle ()

Shuffles playlist.

Returns nothing on success, but error on error.

=cut
sub shuffle
{
    my($self) = @_;
    print $sock "shuffle\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->move ($from, $to)

Moves item $from to $to in playlist.

Returns nothing on success, but error on error.

=cut
sub move
{
    my($self,$from,$to) = @_;
    if($from && $to && $from =~ /\w+/ && $to =~ /\w+/)
    {
        print $sock "move $from $to\n";
    } else {
        return "Must be move(int, int)!";
    }
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->rm ($list)

Removes the playlist $list from the playlist directory.

Returns nothing on success, but error on error.

=cut
sub rm
{
    my($self,$list) = @_;
    print $sock "rm $list\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->save ($list)

Saves current playlist to $list in playlist directory.

Returns nothing on success, but error on error.

=cut
sub save
{
    my($self,$list) = @_;
    print $sock "save $list\n";
    while(<$sock>)
    {
        return $_ if $_ =~ /^ACK/;
        return if $_ =~ /^OK/;
    }
}

=item $foo->search ($type, $what, [$strict = 0])

Searches playlist for entries of type $type (artist, album or title), matching $what. If $strict is set to 1, $what must be completely matched.

Returns matches in array.

=cut
sub search
{
    my($self,$type,$what,$strict) = @_;
    $strict = 0 if !$strict;
    return "Type must be artist, album or title" if $type !~ /^(artist|album|title)$/;
    my $command = ($strict == 0) ? 'search' : 'find';
    print $sock "$command $type $what\n";

    my @list;
    my @tmp;
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^file:/)
        {
            push @list, [@tmp] if @tmp;
            @tmp = $_;
        } else {
            push @tmp, $_;
        }
        return $_ if $_ =~ /^ACK/;
        return @list if $_ =~ /^OK/;
    }
}

=item $foo->list ($foo, [$bar])

Lists alle tags of type $foo (Either 'album' or artist'). If $foo is 'album, $bar can be set to an artist.

Returns array containing tags on success, and error on error.

=cut
sub list
{
    my($self,$foo,$bar) = @_;
    return "Must be list((artist|album),[artist])" if $foo !~ /^(artist|album)$/;
    my $command;
    $bar = '' if !$bar;
    $command = "list $foo $bar\n" if $foo eq 'album';
    $command = "list $foo\n" if $foo eq 'artist';
    print $sock $command;
    my @tmp;
    while(<$sock>)
    {
        chomp;
        return $_ if $_ =~ /^ACK/;
        last if $_ =~ /^OK/;
        push @tmp, $1 if $_ =~ /^(?:Artist|Album):\s(.+)$/;
    }  
    return @tmp;

}

=item $foo->listall ([$path])

Lists all songs and directories in $path (recursively).

Returns array of entries on success, and error on error.

=cut
sub listall
{
    my($self,$path) = @_;
    $path = '' if !$path;
    print $sock "listall $path\n";
    my @tmp;
    while(<$sock>)
    {
        chomp;
        return $_ if $_ =~ /^ACK/;
        last if $_ =~ /^OK/;
        push @tmp, $_;
    }
    return @tmp;
}

=item $foo->listallinfo ([$path])

Lists all songs and directories in $path (recursively), with metadata.

Returns array of entries on success, and error on error.

=cut
sub listallinfo
{
    my($self, $path) = @_;
    $path = '' if !$path;
    print $sock "listallinfo $path\n";

    my @list;
    my @tmp;
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^file:/)
        {
            push @list, [@tmp] if @tmp;
            @tmp = $_;
        } else {
            push @tmp, $_;
        }
        return $_ if $_ =~ /^ACK/;
        return @list if $_ =~ /^OK/;
    }
}

=item $foo->lsinfo ([$path])

Lists all songs and directories in $path, with metadata.

Returns array of entries on success, and error on error.

=cut
sub lsinfo
{
    my($self, $path) = @_;
    $path = '' if !$path;
    print $sock "lsinfo $path\n";

    my @list;
    my @tmp;
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^(file|directory):/)
        {
            push @list, [@tmp] if @tmp;
            @tmp = $_;
        } else {
            push @tmp, $_;
        }
        return $_ if $_ =~ /^ACK/;
        return @list if $_ =~ /^OK/;
    }
}

#-------------------------------------------------------------#
#                     UNFINISHED SUBS                         #
#-------------------------------------------------------------#

sub password
{

}

=todo

 - is_connected()-check on (almost) all functions - connect if not
 - perhaps a 'ping()' every five seconds? Possible without fork? I think not :(

=cut

1;
