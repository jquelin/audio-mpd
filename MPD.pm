#!/usr/bin/perl -w
#
# MPD perl module
# Written for MPD 0.10.0, but should work for most versions.
#
# Copyright (C) 2004 Tue Abrahamsen (twoface@wtf.dk)
# This project's homepage is: http://www.musicpd.org
# Report bugs at: http://www.musicpd.org/mantis/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA	02111-1307	USA
#
package MPD;
use strict;
use IO::Socket;
use constant VERSION => '0.10.0-rc1';

my $sock;
my @playlist;

#-------------------------------------------------------------#
#                        CONFIGURATION                        #
#-------------------------------------------------------------#

my %config = ( 
			   OVERWRITE_PLAYLIST => 1,   # Overwrites playlist, if already exists on save()
			 );

#-------------------------------------------------------------#
#                         BASIC SUBS                          #
#-------------------------------------------------------------#

=item MPD->new ([$host, [$port]])

The constructor.
@param string Host to connect to
@param integer Port to connect to
@return ref Reference to self

=cut
sub new
{
	my($self,$host,$port) = @_;
	$self = {
		# Variables set by class
		module_version => VERSION,
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

Establishes a connections to the MPD server
@return void

=cut
sub connect
{
	my($self) = shift;
	$sock = new IO::Socket::INET
	(
		PeerAddr => $self->{host} || $ENV{'MPD_HOST'} || 'localhost',
		PeerPort => $self->{port} || $ENV{'MPD_PORT'} || 6600,
		Proto => 'tcp',
	);
	die("Could not create socket: $!\n") unless $sock;
	while(<$sock>)
	{
		if(/^OK MPD (.+)$/)
		{
			$self->{version} = $1;
			$self->{connected} = 1;
			last;
		} else {
			die("Could not connect: $!\n");
		}
	}
	$self->getstats;
	$self->getstatus;
	return;
}

=item $foo->geterror ()

Get last error
@return string Error

=cut
sub geterror
{
  my($self) = shift;
  return $self->{ack_error};
}

=item $foo->getstatus ()

Reads server-status into module variables.
@return integer Completion status

=cut
sub getstatus
{
	my($self) = shift;
	my $update = 0;
	print $sock "status\n";
	while(<$sock>)
	{
		chomp;
		if(/^ACK (.+)$/) {
		  $self->{ack_error} = $1;
		  return undef;
		}
		last if $_ eq 'OK';
		if(/^(.[^:]+):\s(.+)$/) {
			$update = 1 if($1 eq 'playlist' && $self->{playlist} && $2 ne $self->{playlist} && $self->{playlist} != 0);
			$self->{$1} = $2;
		}
	}
	$self->getplaylist if $update;
	return 1;
}

=item $foo->getstats ()

Reads serverstats into module variables.
@return integer Completion status
	
=cut
sub getstats
{
	my($self) = shift;
	print $sock "stats\n";
	while(<$sock>)
	{
		chomp;
		if(/^ACK (.+)$/) {
		  $self->{ack_error} = $1;
		  return undef;
		}
		last if $_ eq 'OK';
		$self->{$1} = $2 if /^(.[^:]+):\s(.+)$/;
	}	
	return 1;
}

=item $foo->getplaylist ()

Reads entire playlist
@return integer Completion status

=cut
sub getplaylist
{
	my($self) = shift;
	print $sock "playlistinfo\n";
	
	my @tmp;
	my %hash;
	@playlist = ();
	while(<$sock>)
	{
		chomp;
		if(/^(.[^:]+):\s(.+)$/) 
		{
		  if($1 eq 'file')
		  {
			  push @playlist, { %hash } if %hash;
			  %hash = ();
		  }
		  $hash{$1} = $2;
		}
		if(/^(ACK|OK)/)
		{
			push @playlist, { %hash } if %hash;
			if(/^ACK (.+)$/) {
				$self->{ack_error} = $1;
				return undef;
			}
			return 1 if $_ =~ /^OK/;
		}
	}
}

=item $foo->clearerror ()

Clears current error.
@return integer Completion status

=cut
sub clearerror
{
	my($self) = shift;
	$self->connect;
	print $sock "clearerror\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
				return 1 if /^OK/;
	}
}

=item sub->close ()

Closes current connection to MPD
@return void

=cut
sub close
{
	my($self) = shift;
	if($self->{connected})
	{
	  print $sock "close\n";
	}
	$self->{connected} = 0;
	return;
}

=item $foo->kill ()

Kills MPD
@return void

=cut
sub kill
{
	my($self) = shift;
	$self->connect;
	print $sock "kill\n";
	return;
}

=item $foo->ping ()

Checks connection to MPD
@return integer Connection status

=cut
sub ping
{
	my($self) = shift;
	$self->connect;
	print $sock "ping\n";
	while(<$sock>)
	{
		return 1 if /^OK/;
	}
}

=item $foo->password ($password)

Sends $password to MPD server
@return integer Completion status

=cut
sub password
{
	my($self,$password) = @_;
	$self->connect;
	print $sock "password ".($password || 'default')."\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->urlhandlers ()

Gets list of supported url handlers
@return array URL handlers

=cut
sub urlhandlers
{
	my($self) = shift;
	my @handlers;
	print $sock "urlhandlers\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
    {
      $self->{ack_error} = $1;
      return undef;
    }
    return 1 if /^OK/;
		push @handlers, $1 if $_ =~ /^handler: (.+)$/;
	}
}

=item $foo->DESTROY ()

Destructor
Closes connection to MPD
@return void

=cut
sub DESTROY
{
	my($self) = shift;
	#$self->close; # Why, oh why, does it complain over this? Find out!
}

#-------------------------------------------------------------#
#                  SUBS FOR ALTERING SETTINGS                 #
#-------------------------------------------------------------#

=item $foo->setrepeat ([$status])

Sets status for 'repeat'
@param integer/string New status (0 / 1 / on / off)
@return integer Completion status

=cut
sub setrepeat
{
	my($self,$status) = @_;
	$self->connect;
	my $command;
		if($status && $status =~ /^(0|1|on|off)$/) {
			$status =~ s/off/0/ if $status;
			$status =~ s/on/1/ if $status;
		} else {
			$status = ($self->{repeat} == 1 ? 0 : 1);
		} 
	$command = "repeat $status\n";
	print $sock $command;
	$self->{repeat} = $status;
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->setrandom ([$status])

Sets status for 'random'
@param integer/string New status (0 / 1 / on / off)
@return integer Completion status
	
=cut
sub setrandom
{
	my($self,$status) = @_;
	$self->connect;
	my $command;
		if($status && $status =~ /^(0|1|on|off)$/) {
			$status =~ s/off/0/ if $status;
			$status =~ s/on/1/ if $status;
		} else {
			$status = ($self->{random} == 1 ? 0 : 1);
		}
	$command = "random $status\n";
	print $sock $command;
	$self->{random} = $status;
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->setfade ($secs)

Sets amount of seconds used for crossfading
@param integer Seconds
@return integer Completion status

=cut
sub setfade
{
	my($self,$secs) = @_;
	$self->connect;
	print $sock "crossfade $secs\n";
	$self->{xfade} = $secs;
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->setvolume ($volume)

Sets volume
@param integer/string New wolume (eg. 0 / 42 / -13 / +45)
@return integer Completion status

=cut
sub setvolume
{
	my($self,$volume) = @_;
	$self->connect;
	
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
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

#-------------------------------------------------------------#
#                  SUBS FOR COMMON PLAYBACK                   #
#-------------------------------------------------------------#

=item $foo->play ([$song])

Starts playback
@param integer Song to play
@return integer Completion status

=cut
sub play 
{
	my($self,$number) = @_;
	$self->connect;
	if($self->{state} eq 'pause') {
	  print $sock "pause\n";
	} else {
		$number = '' if !$number;
	  print $sock "play $number\n";
	}
	while(<$sock>)
	{
		if($_ =~ /^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if $_ =~ /^OK/;
	}
}

=item $foo->pause ()

Pauses playback, resumes from pause if already paused
@return integer Completion status

=cut
sub pause
{
	my($self) = shift;
	$self->connect;
	print $sock "pause\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->stop ()

Stops playback
@return integer Completion status

=cut
sub stop
{
	my($self) = shift;
	$self->connect;
	print $sock "stop\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->next ()

Plays next song in playlist
@return integer Completion status

=cut
sub next
{
	my($self) = shift;
	$self->connect;
	print $sock "next\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	} 
}

=item $foo->prev ()

Plays previous song in playlist
@return integer Completion status

=cut
sub prev
{
	my($self) = shift;
	$self->connect;
	print $sock "previous\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->setpause ([$toggle])

Toggles pausemode
@param integer Pause status
@return integer Completion status

=cut
sub setpause
{
	my($self,$toggle) = @_;
	$self->connect;
	print $sock "pause $toggle\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->seek ($time, $song)

Seeks to specific position
@param integer Position in seconds
@param integer Song
@return integer Completion status

=cut
sub seek
{
	my($self,$time,$song) = @_;
	$self->connect;
	if($song && $time && $song =~ /^\w+$/ && $time =~ /^\w+$/)
	{
		print $sock "seek $song $time\n";
	} elsif($time && $time =~ /^\w+$/ && $self->{song}) {
	  print $sock "seek ",$self->{song}," $time\n";
	} else {
		return 0; 
	}
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

#-------------------------------------------------------------#
#                 SUBS FOR PLAYLIST-HANDLING                  #
#-------------------------------------------------------------#

=item $foo->clear ()

Clears playlist
@return integer Completion status

=cut
sub clear
{
	my($self) = shift;
	$self->connect;
	print $sock "clear\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->add ([$path])

Adds path to playlist
@param string Path to add, if not supplied, all songs is added
@return integer Completion status

=cut
sub add
{
	my($self,$path) = @_;
	$self->connect;
	$path = '' if !$path;
	print $sock "add \"$path\"\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		if(/^OK/)
		{
		  $self->{playlist}++;
		  return 1;
		}
	}
}

=item $foo->delete ($song)

Deletes song[s] from the playlist
@param integer/string Song[-range] to delete
@return integer Completion status

=cut
sub delete
{
	my($self,$song) = @_;
	$self->connect;
	if($song =~ /^(\w)-(\w)$/)
	{
		for(my $i = $1 ; $i <= $2 ; $i++)
		{
			$self->delete($i);
		}
	} else {
		print $sock "delete $song\n";
	}
	while(<$sock>)
	{
	  if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		if(/^OK/)
		{
		  $self->{playlist}++;
		  return 1;
		}
	}
} 

=item $foo->load ($list)

Loads playlist
@param string Playlistname
@return integer Completion status

=cut
sub load
{
	my($self,$list) = @_;
	$self->connect;
	print $sock "load $list\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->update ()

Updates MPD database
@return integer Completion status

=cut
sub update
{
	my($self) = shift;
	$self->connect;
	print $sock "update\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->swap ($foo, $bar)

Swaps songs in playlist
@param integer Song 1
@param integer Song 2
@return integer Completion status

=cut
sub swap
{
	my($self,$foo,$bar) = @_;
	$self->connect;
	if($foo && $bar && $foo =~ /\w+/ && $bar =~ /\w+/)
	{
		print $sock "swap $foo $bar\n";
	} else {
		return "Must be swap(int, int)!";
	}
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		if(/^OK/)
		{
		  $self->{playlist}++;
		  return 1;
		}
	}
}

=item $foo->shuffle ()

Shuffles playlist
@return integer Completion status

=cut
sub shuffle
{
	my($self) = shift;
	$self->connect;
	print $sock "shuffle\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->move ($from, $to)

Moves songs in playlist
@param integer From #
@param integer To #
@return integer Completion status

=cut
sub move
{
	my($self,$from,$to) = @_;
	$self->connect;
	if($from && $to && $from =~ /\w+/ && $to =~ /\w+/)
	{
		print $sock "move $from $to\n";
	} else {
		return "Must be move(int, int)!";
	}
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		if(/^OK/)
		{
		  $self->{playlist}++;
		  return 1;
		}
	}
}

=item $foo->rm ($list)

Removes playlist
@param string Playlistname
@return integer Completion status

=cut
sub rm
{
	my($self,$list) = @_;
	$self->connect;
	print $sock "rm $list\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->save ($list)

Saves playlist
@param string Playlistname
@return integer Completion status

=cut
sub save
{
	my($self,$list) = @_;
	$self->connect;
	print $sock "save $list\n";
	while(<$sock>)
	{
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  if($1 =~ /^A file or directory already exists with the name/ && $config{'OVERWRITE_PLAYLIST'}) {
			$self->rm($list);
			$self->save($list);
		  }
		  return undef;
		}
		return 1 if /^OK/;
	}
}

=item $foo->search ($type, $what, [$strict = 0])

Searching playlist for songs
@param string Search-criteria-type (filename | artist | album | title)
@param string Search-criteria-string
@param integer 1 for casesensitive search
@return array Song-hashes
Returns matches in array-hash.

=cut
sub search
{
	my($self,$type,$what,$strict) = @_;
	$self->connect;
	$strict = 0 if !$strict;
	return undef if $type !~ /^(artist|album|title|filename)$/;
	my $command = ($strict == 0 ? 'search' : 'find');
	print $sock "$command $type $what\n";

	my @list;
	my %hest;
	while(<$sock>)
	{
		chomp;
		if($_ =~ /^(.[^:]+):\s(.+)$/)
		{
			if($1 eq 'file')
			{
				push @list, { %hest } if %hest;
				%hest = ();
			}
			$hest{$1} = $2;
		}
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		if(/^OK/)
		{
					push @list, { %hest } if %hest;
		  return @list;
		}
	}
}

=item $foo->list ($foo, [$bar])

Lists tags
@param string Tagtype (album / artist)
@param string Artist (if tagtype = album)
@return array/integer Tags

=cut
sub list
{
	my($self,$foo,$bar) = @_;
	$self->connect;
	return "Must be list((artist|album),[artist])" if $foo !~ /^(artist|album)$/;
	my $command;
	$bar = '' if !$bar;
		if($foo eq 'album') {
			$command = "list $foo $bar\n";
		} else {
			$command = "list $foo\n";
		}
	print $sock $command;
	my @tmp;
	while(<$sock>)
	{
		chomp;
		if(/^ACK (.+)$/)
		{
			$self->{ack_error} = $1;
			return undef; 
		}
		last if /^OK/;
		push @tmp, $1 if $_ =~ /^(?:Artist|Album):\s(.+)$/;
	} 
	return @tmp;

}

=item $foo->listall ([$path])

Lists songs and directories
@param string Path
@return array/integer Entries

=cut 
sub listall
{
	my($self, $path) = @_;
	$self->connect;
	$path = '' if !$path;
	print $sock "listall \"$path\"\n";
	my @tmp;
	while(<$sock>)
	{
		chomp;
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return undef;
		}
		last if /^OK/;
		push @tmp, $_;
	}
	return @tmp;
}

=item $foo->listallinfo ([$path]) 

Lists songs and directories recursively w/ metadata
Must be used in conjunction with nextinfo()
@param string Path
@return void

=cut
sub listallinfo
{
	my($self, $path) = @_;
	$self->connect;
	$path = '' if !$path;
	print $sock "listallinfo \"$path\"\n";
}

=item $foo->lsinfo ([$path])

Lists songs and directories w/ metadata
Must be used in conjunction with nextinfo()
@param string Path
@return void

=cut
sub lsinfo
{
	my($self, $path) = @_;
	$self->connect;
	$path = '' if !$path;
	print $sock "lsinfo \"$path\"\n";
}

=item $foo->nextinfo ()

Returns next element from lsinfo() or listallinfo()
@example while(%bar = $foo->nextinfo) { print $bar{'file'}; }
@return hash Element

=cut
sub nextinfo
{
	my($self) = shift;
	my %hash;
	while(<$sock>)
	{
				chomp;
		$hash{$1} = $2 if($_ =~ /^(.[^:]+):\s(.+)$/);
		if(/^ACK (.+)$/)
		{
		  $self->{ack_error} = $1;
		  return;
		}
		return if /^OK/; # Unfortunately, we can't have 'return 1' on succes, as a while(nextinfo) won't stop
		last if /^(Time|directory|playlist):\s/;
	}
	return %hash;
} 

#-------------------------------------------------------------#
#                         CUSTOM SUBS                         #
#-------------------------------------------------------------#

=item $foo->searchadd ($type, $string)

Searches and adds songs
@param string Search-criteria-type (artist / album / artist / filename)
@param string Search-criteria-string
@returns integer Completion status

=cut
sub searchadd
{
	my($self,$type,$string) = @_;
	my @songs = $self->search($type, $string);
	if($#songs > -1) {
	  print $sock "command_list_begin\n";
	  foreach my $foo (@songs)
	  {
		  my %hash = %$foo;
		  print $sock "add \"".$hash{'file'}."\"\n";
	  }
	  print $sock "command_list_end\n";  
	  while(<$sock>)
	  {
		  if(/^ACK (.+)$/)
		  {
			$self->{ack_error} = $1;
			return undef;
		  }
		  if(/^OK/)
		  {
			$self->{playlist} = $self->{playlist} + $#songs + 1;
			return 1;
		  }
	  }    
	}
	return 0;
}

=item $foo->playlist ()

Returns reference to playlist
@return ref

=cut
sub playlist
{
	my($self) = shift;
	$self->getplaylist if !$playlist[0];
	return \@playlist;
}

=item $foo->gettitle ([$song])

Return songtitle
@param integer Songnumber
@return string Songtitle

=cut
sub gettitle
{
	my($self,$song) = @_;
	my($artist, $title);
	
	$self->getstatus;
	$self->getplaylist if !$playlist[0];
	my $info = $song || $self->{song} || 'false';
	return '' if !$self->{playlistlength} || $info eq 'false' || ($info ne 'false' && $self->{playlistlength}-1 < $info);
	return $playlist[$info]{'Artist'}.' - '.$playlist[$info]{'Title'} if($playlist[$info]{'Artist'} && $playlist[$info]{'Title'});
	return $playlist[$info]{'file'};
}

=item $foo->gettimeformat ()
Written by decius (jesper@noehr.org)

Returns formatted time of currently playing song
@return string Time

=cut
sub gettimeformat
{
	my($self) = shift;
	$self->getstatus;
	return '' if !$self->{playlistlength} || !$self->{song};
	my($psf,$tst) = split /:/, $self->{'time'};
	return sprintf("%d:%02d/%d:%02d",
		   ($psf / 60), # minutes so far
		   ($psf % 60), # seconds - minutes so far
		   ($tst / 60), # minutes total
		   ($tst % 60));# seconds - minutes total
}

1;
