#!/usr/bin/perl -w
#
# MPD perl module
# Written for MPD 0.10.0, but should work for most versions.
#
# Copyright (C) 2004 Tue Abrahamsen (twoface@wtf.dk)
# This project's homepage is: http://www.musicpd.org
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
# 0.10.0-alpha6
#  - Changed @playlist syntax ($playlist[song-number]{info-to-get} eg. $playlist[42]{'file'})
#  - Removed deprecated getsonginfo()
#  - Moved gettitle() and gettimeformat() to 'Custom subs'
#  - Altered gettitle()'s errorhandling a bit
# 
# 0.10.0-alpha5
#  - Made getsonginfo() return a hash instead of an array
#  - Streamlined add()/delete()/move()/swap()
#  - Made (almost) all functions undef on succes and 1 on error. Last error can be retrieved by $self->geterror()
#  - search() now accepts filenames too (thanks sbh)
#  - delete() can take ranges (thanks sbh)
#  - Added the 'Custom functions'-part
#  - Added searchadd() (thanks sbh)
#  - Repaired add()
#  - Added playlist()
#
# 0.10.0-alpha4
#  - Fixed bug where last song on playlist was not present
#  - Made getstatus() call playlistinfo if playlist had changed
#  - Implemented getsonginfo() for returning information from @playlist (Thanks msells)
#  - Added $self->{module_version}
#  - Empties @playlist, when renewing it
#  - A bit of optimizing and cleanup around getplaylist (Thanks msells)
#
# 0.10.0-alpha3
#  - Fixed error in add()-comments
#  - Moved $host and $port parameter to new() - It finally works!
#
# 0.10.0-alpha2
#  - Added nextinfo() and changed lsinfo() and listallinfo()
#  - Changed version-numbering to fit MPD standards
#
# 0.1
#  - Initial release
#
package MPD;
use strict;
use IO::Socket;

my $version = '0.10.0-alpha6';
my $sock;
my @playlist;

#-------------------------------------------------------------#
#                       BASIC SUBS                            #
#-------------------------------------------------------------#

=item MPD->new ([$host, [$port]])

The constructor. Saves information on MPD server at either specified - , enviroment variables - , og preset host:port.

Returns reference to self.

=cut
sub new
{
    my($self,$host,$port) = @_;
    $self = {
        # Variables set by class
        module_version => $version,
        version => undef,
        connected => undef,
        password => undef,
        ack_error => undef,
        host => $host,
        port => $port,
        # Variables set by command 'status'
        volume => undef,
        repeat => undef,
        random => undef,
        state => undef,
        playlist => 0,
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

=item $foo->connect ()

Connects to MPD server.

Returns nothing, but dies on failed connection.

=cut
sub connect
{
    my($self) = @_;
    $sock = new IO::Socket::INET
    (
        PeerAddr => $self->{host} || $ENV{'MPD_HOST'} || 'localhost',
        PeerPort => $self->{port} || $ENV{'MPD_PORT'} || 2100,
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
    return;
}

=item $foo->geterror

Returns last error

=cut
sub geterror
{
  my($self) = @_;
  return $self->{ack_error};
}

=item $foo->getstatus

Reads server-status into module variables.

Returns nothing.

=cut
sub getstatus
{
    my($self) = @_;
    my $update = 0;
    print $sock "status\n";
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^ACK (.+)$/) {
          $self->{ack_error} = $1;
          undef;
        }
        last if $_ eq 'OK';
        if($_ =~ /^(.+):\s(.+)$/) {
            $update = 1 if($1 eq 'playlist' && $1 ne $self->{playlist});
            $self->{$1} = $2;
        }
    }
    &getplaylist if $update;
    return 1;
}

=item $foo->getstats

Reads serverstats into module variables.
    
Returns nothing.
    
=cut
sub getstats
{
    my($self) = @_;
    print $sock "stats\n";
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^ACK (.+)$/) {
          $self->{ack_error} = $1;
          undef;
        }
        last if $_ eq 'OK';
        $self->{$1} = $2 if $_ =~ /^(.+):\s(.+)$/;
    }   
    return 1;
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
    my %hash;
    @playlist = ();
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^(.+):\s(.+)$/) 
        {
          if($1 eq 'file')
          {
              push @playlist, { %hash } if %hash;
              %hash = ();
          }
          $hash{$1} = $2;
        }
        if($_ =~ /^(ACK|OK)/)
        {
            push @playlist, [@tmp] if @tmp;
            if($_ =~ /^ACK (.+)$/) {
                $self->{ack_error} = $1;
                undef;
            }
            return 1 if $_ =~ /^OK/;
        }
    }
}

=item $foo->clearerror ()

Clears current error.

Returns nothing on success, but error on error.

=cut
sub clearerror
{
    my($self) = @_;
    &connect;
    print $sock "clearerror\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item sub->close ()

Closes current connection to MPD.

Returns nothing.

=cut
sub close
{
    my($self) = @_;
    if($self->{connected})
    {
      print $sock "close\n";
    }
    $self->{connected} = 0;
    return;
}

=item $foo->kill ()

Kills MPD.

Returns nothing.

=cut
sub kill
{
    my($self) = @_;
    &connect;
    print $sock "kill\n";
    return;
}

=item $foo->ping ()

Returns OK if connection is established to MPD.

=cut
sub ping
{
    my($self) = @_;
    &connect;
    print $sock "ping\n";
    while(<$sock>)
    {
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->password ($password)

Sends $password to MPD server.

Returns output.

=cut
sub password
{
    my($self,$password) = @_;
    &connect;
    print $sock "password ".($password || 'default')."\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
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
    &connect;
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
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->setrandom ([$status])

Sets 'random'-status to $status if specified. If not, status is shifted. $status must be 0, 1, on or off.

Returns nothing on success, but error on error.
    
=cut
sub setrandom
{
    my($self,$status) = @_;
    &connect;
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
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->setfade ($secs)

Sets crossfading to $secs seconds.

Returns nothing on success, but error on error.

=cut
sub setfade
{
    my($self,$secs) = @_;
    &connect;
    print $sock "crossfade $secs\n";
    $self->{xfade} = $secs;
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
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
    &connect;
    
    if($volume =~ /^(-|\+)/ && $self->{volume})
    {
        $volume = $self->{volume} + $1 if $volume =~ /^\+(\w+)$/; 
        $volume = $self->{volume} - $1 if $volume =~ /^-(\w+)$/;
    }
    if($volume && $volume > -1 && $volume < 101)
    {
        print $sock "setvol $volume\n";
    } else {
        return "Must be setvolume(int)";
    }
    $self->{volume} = $volume;
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
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
    &connect;
    $number--;
    print $sock "play $number\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->pause

Pauses playback, but resumes from pause if already paused.

Returns nothing on success, but error on error.

=cut
sub pause
{
    my($self) = @_;
    &connect;
    print $sock "pause\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->stop ()

Stops playback.

Returns nothing on success, but error on error.

=cut
sub stop
{
    my($self) = @_;
    &connect;
    print $sock "stop\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->next ()

Plays next song in playlist.

Returns nothing on success, but error on error.

=cut
sub next
{
    my($self) = @_;
    &connect;
    &connect;
    print $sock "next\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    } 
}

=item $foo->prev ()

Plays previous song in playlist.

Returns nothing on success, but error on error.

=cut
sub prev
{
    my($self) = @_;
    &connect;
    print $sock "previous\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->setpause ([$toggle])

Toggles pausemode. Pauses if playing, plays if paused. Sets pause to $toggle if set. $toggle must be 0 or 1.

Returns nothing on success, but error on error.

=cut
sub setpause
{
    my($self,$toggle) = @_;
    &connect;
    print $sock "pause $toggle\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->seek ($time, $song)

Seeks to position $time (in seconds) in song $song. If $song is not supplied, current song is chosen

Returns nothing on success, but error on error.

=cut
sub seek
{
    my($self,$time,$song) = @_;
    &connect;
    if($song && $time && $song =~ /^\w+$/ && $time =~ /^\w+$/)
    {
        print $sock "seek $song $time\n";
    } elsif($song && $song =~ /^\w+$/ && $self->{song}) {
      print $sock "seek ",$self->{song}," $time\n";
    } else {
        return 0; 
    }
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
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
    &connect;
    print $sock "clear\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->add ([$path])

Adds $path to playlist. $path must be file or directory currently in database.

If $path is not given, all songs are added to the playlist.

Returns nothing on succes, but error on error.

=cut
sub add
{
    my($self,$path) = @_;
    &connect;
    print $sock "add \"$path\"\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        if($_ =~ /^OK/)
        {
          $self->{playlist}++;
          return 1;
        }
    }
}

=item $foo->delete ($song)

Deletes songs from the playlist. $song must either be an integer or integer-integer for song-range..

Returns nothing on success, but error on error.

=cut
sub delete
{
    my($self,$song) = @_;
    &connect;
    if($song =~ /^(\w)-(\w)$/)
    {
        for(my $i = $1 ; $i <= $2 ; $i++)
        {
            &delete($i);
        }
    } else {
        print $sock "delete $song\n";
    }
    while(<$sock>)
    {
      if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        if($_ =~ /^OK/)
        {
          $self->{playlist}++;
          return 1;
        }
    }
} 

=item $foo->load ($list)

Loads $list playlist from the playlist directory.

Returns nothing on succes, but error on error.

=cut
sub load
{
    my($self,$list) = @_;
    &connect;
    print $sock "load $list\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->update ()

Searches music directory for new music, and removes old music from the database.

Returns nothing on success, but error on error.

=cut
sub update
{
    my($self) = @_;
    &connect;
    print $sock "update\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->swap ($foo, $bar)

Swaps $foo and $bar in playlist. $foo and $bar must be integers.

Returns nothing on success, but error on error.

=cut
sub swap
{
    my($self,$foo,$bar) = @_;
    &connect;
    if($foo && $bar && $foo =~ /\w+/ && $bar =~ /\w+/)
    {
        print $sock "swap $foo $bar\n";
    } else {
        return "Must be swap(int, int)!";
    }
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        if($_ =~ /^OK/)
        {
          $self->{playlist}++;
          return 1;
        }
    }
}

=item $foo->shuffle ()

Shuffles playlist.

Returns nothing on success, but error on error.

=cut
sub shuffle
{
    my($self) = @_;
    &connect;
    print $sock "shuffle\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->move ($from, $to)

Moves item $from to $to in playlist.

Returns nothing on success, but error on error.

=cut
sub move
{
    my($self,$from,$to) = @_;
    &connect;
    if($from && $to && $from =~ /\w+/ && $to =~ /\w+/)
    {
        print $sock "move $from $to\n";
    } else {
        return "Must be move(int, int)!";
    }
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        if($_ =~ /^OK/)
        {
          $self->{playlist}++;
          return 1;
        }
    }
}

=item $foo->rm ($list)

Removes the playlist $list from the playlist directory.

Returns nothing on success, but error on error.

=cut
sub rm
{
    my($self,$list) = @_;
    &connect;
    print $sock "rm $list\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->save ($list)

Saves current playlist to $list in playlist directory.

Returns nothing on success, but error on error.

=cut
sub save
{
    my($self,$list) = @_;
    &connect;
    print $sock "save $list\n";
    while(<$sock>)
    {
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        return 1 if $_ =~ /^OK/;
    }
}

=item $foo->search ($type, $what, [$strict = 0])

Searches playlist for entries of type $type (artist, album, title or filename), matching $what. If $strict is set to 1, $what must be completely matched.

Returns matches in array-hash.

=cut
sub search
{
    my($self,$type,$what,$strict) = @_;
    &connect;
    $strict = 0 if !$strict;
    return undef if $type !~ /^(artist|album|title|filename)$/;
    my $command = ($strict == 0) ? 'search' : 'find';
    print $sock "$command $type $what\n";

    my @list;
    my %hest;
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^(.+):\s(.+)$/)
        {
            if($1 eq 'file')
            {
                push @list, { %hest } if %hest;
                %hest = ();
            }
            $hest{$1} = $2;
        }
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        if($_ =~ /^OK/)
        {
          return @list;
        }
    }
}

=item $foo->list ($foo, [$bar])

Lists alle tags of type $foo (Either 'album' or artist'). If $foo is 'album, $bar can be set to an artist.

Returns array containing tags on success, and error on error.

=cut
sub list
{
    my($self,$foo,$bar) = @_;
    &connect;
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
        if($_ =~ /^ACK (.+)$/)
        {
            $self->{ack_error} = $1;
            undef; 
        }
        last if $_ =~ /^OK/;
        push @tmp, $1 if $_ =~ /^(?:Artist|Album):\s(.+)$/;
    } 
    return @tmp;

}

=item $foo->listall ([$path])

Lists all songs and directories recursively in $path.

Returns array of entries on success, and error on error.

=cut 
sub listall
{
    my($self,$path) = @_;
    &connect;
    $path = '' if !$path;
    print $sock "listall $path\n";
    my @tmp;
    while(<$sock>)
    {
        chomp;
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          undef;
        }
        last if $_ =~ /^OK/;
        push @tmp, $_;
    }
    return @tmp;
}

=item $foo->listallinfo ([$path]) 

Sends command 'listallinfo $path', which lists all songs and directories recursively in $path with full metadata.

Must be processed with nextinfo(). Other use may break program usage!

Returns nothing.

=cut
sub listallinfo
{
    my($self, $path) = @_;
    &connect;
    $path = '' if !$path;
    print $sock "listallinfo $path\n";
}

=item $foo->lsinfo ([$path])

Sends command 'lsinfo $path', which lists all songs and directories in $path with full metadata.

Must be processed with nextinfo(). Other use may break program usage!

Returns nothing.

=cut
sub lsinfo
{
    my($self, $path) = @_;
    &connect();
    $path = '' if !$path;
    print $sock "lsinfo $path\n";
}

=item $foo->nextinfo ()

Returns the next entry from either the lsinfo() or listallinfo() commands. Data is returned in a hash.

Example: while($bar = $foo->nextinfo) { print $bar{'file'}; }

=cut
sub nextinfo
{
    my($self) = @_;
    my %hash;
    while(<$sock>)
    {
        $hash{$1} = $2 if($_ =~ /^(.+):\s(.+)$/);
        if($_ =~ /^ACK (.+)$/)
        {
          $self->{ack_error} = $1;
          return;
        }
        return if $_ =~ /^OK/; # Unfortunately, we can't have 'return 1' on succes, as a while(nextinfo) won't stop
        last if($_ =~ /^(Time|directory|playlist):\s/);
    }
    return %hash;
} 

#-------------------------------------------------------------#
#                       CUSTOM SUBS                           #
#-------------------------------------------------------------#

=item $foo->searchadd ($type, $string)

Searches for songs where $type contains $string, and adds those to the playlist.
$type must be 'artist','album','title' or 'filename'.

Returns nothing.

=cut
sub searchadd
{
    my($self,$type,$string) = @_;
    my @songs = $self->search($type, $string);
    my $foo;
    foreach $foo (@songs)
    {
        my %hash = %$foo;
        $self->add($hash{'file'});
    }
    return 0;
}

=item $foo->playlist ()

Returns the playlist in array-hash

=cut
sub playlist
{
    my($self) = @_;
    return \@playlist;
}

=item $foo->gettitle ([$song])

Returns title of $song if specified, otherwise playing song.
Title is made of id3-tag-information if available, otherwise filename.

=cut
sub gettitle
{
    my($self,$song) = @_;
    my($artist, $title);
    
    &getstatus;
    my $info = $song || $self->{song} || 'false';
#    return '' if !$self->{playlistlength} || (!$info && $info != 0) || $self->{playlistlength}-1 < $info;
    return '' if !$self->{playlistlength} || $info eq 'false' || ($info ne 'false' && $self->{playlistlength}-1 < $info);
    return $playlist[$info]{'Artist'}.' - '.$playlist[$info]{'Title'} if($playlist[$info]{'Artist'} && $playlist[$info]{'Title'});
    return $playlist[$info]{'file'};
}

=item $foo->gettimeformat
Written by decius (jesper@noehr.org)

Returns formatted time of currently playing song.

=cut
sub gettimeformat
{
    my($self) = @_;
    &getstatus;
    return '' if !$self->{playlistlength} || !$self->{song};
    my($psf,$tst) = split /:/, $self->{'time'};
    return sprintf("%d:%02d/%d:%02d",
           ($psf / 60), # minutes so far
           ($psf % 60), # seconds - minutes so far
           ($tst / 60), # minutes total
           ($tst % 60));# seconds - minutes total
}



#-------------------------------------------------------------#
#                     UNFINISHED SUBS                         #
#-------------------------------------------------------------#

=todo


=cut

1;
