#!/usr/bin/perl -w
#
# MPD perl module
# Written for MPD 0.11.1
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package MPD;
use strict;
use IO::Socket;
use Data::Dumper;
use constant VERSION => '0.12.0-rc4';

# Socket handle
my $sock;
# Array holding playlist-entries in hashes
my @playlist;

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
				# parameteres. Default: no
				ALLOW_TOGGLE_STATES => 0,
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

sub new
{
	my($self,$mpd_host,$mpd_port) = @_;
	$self = {
		# Variables set by class
		module_version => VERSION,
		mpd_version => undef,
		password => undef,
		# Variables for ACK error
		ack_error_id => undef,
		ack_error_command_id => undef,
		ack_error_command => undef,
		ack_error => undef,
		# MPD connection information
		mpd_host => $mpd_host || $ENV{'MPD_HOST'} || $config{'DEFAULT_MPD_HOST'},
		mpd_port => $mpd_port || $ENV{'MPD_PORT'} || $config{'DEFAULT_MPD_PORT'},
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
	};
	bless($self);
	$self->_connect;
	return $self;
}

sub is_connected
{
	my($self) = shift;
	# No need to check, if socket has not been initialized
	if($sock)
	{
		print $sock "ping\n";
		if(<$sock> =~ /^OK/)
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
	print $sock "close\n";
	return 1;
}

sub kill_mpd
{
	my($self) = shift;
	$self->_connect;
	print $sock "kill\n";
	return 1;
}

sub send_password
{
	my($self) = shift;
	$self->_connect;
	print $sock "password ".$self->{password}."\n";
	$self->_process_feedback;
	return 1;
}

sub get_urlhandlers
{
	my($self) = shift;
	$self->_connect;
	my @handlers;
	print $sock "urlhandlers\n";
	foreach($self->_process_feedback)
	{
		push @handlers, $1 if /^handler: (.+)$/;
	}
	return @handlers;
}

sub get_error
{
	my($self) = shift;
	return ( 													# Let's return an array
			$self->{ack_error_id},				# [0] What is the ID of the error?
			$self->{ack_error},						# [1] Human readable error-message
			$self->{ack_error_command},		# [2] The command that caused the error
			$self->{ack_error_command_id}	# [3] What number the command was in the command_list (if used)
		);
}

sub END
{
	print $sock "close\n";
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
	$sock = new IO::Socket::INET
	(
		PeerAddr => $self->{mpd_host},
		PeerPort => $self->{mpd_port},
		Proto => 'tcp',
	);
	die("Could not create socket: $!\n") unless $sock;
	if(<$sock> =~ /^OK MPD (.+)$/)
	{
		$self->{version} = $1;
	} else {
		die("Could not connect: $!\n");
	}
	$self->_get_status;
	return 1;
}

sub _process_feedback
{
	my($self) = shift;
	my @output;
	while(<$sock>) 
	{
		chomp;
		# Did we cause an error? Save the data!
		if(/^ACK \[(\d+)\@(\d+)\] {(.+)} (.+)$/)
		{
	    $self->{ack_error_id} = $1;
	    $self->{ack_error_command_id} = $2;
  	  $self->{ack_error_command} = $3;
    	$self->{ack_error} = $4;
			return undef;
		}
		last if /^OK/;
		push @output, $_;
	}
	# Let's return the output for post-processing
	return @output;
}

sub _get_status
{
	my($self) = shift;
	$self->_connect;
	my $update_pl = 0;
	print $sock "status\n";
	foreach($self->_process_feedback)
	{
		if(/^(.[^:]+):\s(.+)$/)
		{
			$update_pl = $2 if $1 eq 'playlist';
	  	$self->{$1} = $2;
		}
	}
	$self->_get_playlist($update_pl) if $playlist[0];
	return 1;
}

sub _get_stats
{
	my($self) = shift;
	$self->_connect;
	print $sock "stats\n";
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
	$old_playlist_id = -1 if !defined($old_playlist_id);
	print $sock "plchanges $old_playlist_id\n";
	my @tmp;
	my %hash;
	# Update playlist with new information
	foreach($self->_process_feedback)
	{
		if(/^(.[^:]+):\s(.+)$/)
		{
			if($1 eq 'file')
			{
				$playlist[$hash{'Pos'}] = { %hash } if defined($hash{'Pos'});
				%hash = ();
			} 
			$hash{$1} = $2;
		}
	}
	$playlist[$hash{'Pos'}] = { %hash } if defined($hash{'Pos'});

	# Deletes songs no longer in the playlist
	for(my $i = ($#playlist - ($self->{playlistlength} -1)) ; $i != 0 ; $i--)
	{
		delete($playlist[$#playlist]);
	}
	return 1;
}

#-------------------------------------------#
#           INTERNAL METHODS - END          #
#-------------------------------------------#

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
	
	print $sock "repeat $mode\n";
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
	
	print "random $mode\n";
  print $sock "random $mode\n";
	$self->{random} = $mode;
  return $self->_process_feedback;
}

sub set_fade
{
	my($self,$fade_value) = @_;
	$self->_connect;
	$fade_value = 0 if !defined($fade_value);
	print $sock "crossfade $fade_value\n";
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

	print $sock "setvol $volume\n";
	$self->{volume} = $volume;
	return $self->_process_feedback;
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
	print $sock "$command $number\n";
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
	my($self) = shift;
	$self->_connect;
	print $sock "pause\n";
	return $self->_process_feedback;
}

sub stop
{
	my($self) = shift;
	$self->_connect;
	print $sock "stop\n";
	return $self->_process_feedback;
}

sub next
{
	my($self) = shift;
	$self->_connect;
	print $sock "next\n";
	return $self->_process_feedback;
}

sub prev
{
	my($self) = shift;
	$self->_connect;
	print $sock "previous\n";
	return $self->_process_feedback;
}

sub seek
{
	my($self,$position,$song,$from_id) = @_;
	$self->_connect;
	my $command = (defined($from_id) && $from_id == 1 ? 'seekid' : 'seek');
	if(defined($song) && defined($position) && $song =~ /^\d+$/ && $position =~ /^\d+$/)
	{
		print $sock "$command $song $position\n";
	} elsif(defined($position) && $position =~ /\d+$/ && $self->{song}) {
		print $sock "$command ".$self->{song}." $position\n";
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
#            with the current og saved playlists.             #
###############################################################

sub clear
{
	my($self) = shift;
	$self->_connect;
	print $sock "clear\n";
	return $self->_process_feedback;
}

sub add
{
	my($self,$path) = @_;
	$self->_connect;
	$path = '' if !defined($path);
	print $sock "add \"$path\"\n";
	return $self->_process_feedback;
}

sub delete
{
	my($self,$song,$from_id) = @_;
	$self->_connect;
	return undef if !defined($song) || $song !~ /^\d+$/;
	my $command = (defined($from_id) && $from_id == 1 ? 'deleteid' : 'delete');
	if($song =~ /^(\d+)-(\d+)$/)
	{
		for(my $i = $1 ; $i <= $2 ; $i++)
		{
			$self->$command($i);
		}
	} else {
		print $sock "$command $song\n";
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
	print $sock "load \"$playlist\"\n";
	return $self->_process_feedback;
}

sub updatedb
{
	my($self) = shift;
	$self->_connect;
	print $sock "update\n";
	return $self->_process_feedback;
}

sub swap
{
	my($self,$song_from,$song_to,$from_id) = @_;
	$self->_connect;
	if(defined($song_from) && defined($song_to) && $song_from =~ /^\d+$/ && $song_to =~ /^\d+$/)
	{
		my $command = (defined($from_id) && $from_id == 1 ? 'swapid' : 'swap');
		print $sock "$command $song_from $song_to\n";
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
	print $sock "shuffle\n";
	return $self->_process_feedback;
}

sub move
{
	my($self,$song,$new_pos,$from_id) = @_;
	$self->_connect;
	if(defined($song) && defined($new_pos) && $song =~ /^\d+$/ && $new_pos =~ /^\d+$/)
	{
		my $command = (defined($from_id) && $from_id == 1 ? 'moveid' : 'move');
		print $sock "$command $song $new_pos\n";
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
	print $sock "rm \"$playlist\"\n";
	return $self->_process_feedback;
}

sub save
{
	my($self,$playlist) = @_;
	return undef if !defined($playlist);
	$self->_connect;
	print $sock "save \"$playlist\"\n";
	if(!$self->_process_feedback)
	{
		# Does the playlist already exist?
		if(${$self->get_error}[0] == 56 && $config{'OVERWRITE_PLAYLIST'})
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
	print $sock "$command $type \"$string\"\n";

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
	print $sock ($type eq 'album' ? "list album \"$artist\"\n" : "list artist\n");
	
	#	Strip unneccesary information
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
	print $sock "listall \"$path\"\n";
	return $self->_process_feedback;
}

sub listallinfo
{
	my($self,$path) = @_;
	$self->_connect;
	$path = '' if !defined($path);
	print $sock "listallinfo \"$path\"\n";
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
	print $sock "lsinfo \"$path\"\n";
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
	return undef if !defined($song);
	print $sock "playlist".(defined($from_id) && $from_id == 1 ? 'id' : 'info')." $song\n";
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
		print $sock "command_list_begin\n";
		foreach(@results)
		{
			my %hash = %$_;
			print $sock "add \"".$hash{'file'}."\"\n";
		}
		print $sock "command_list_end\n";
		if($self->_process_feedback)
		{
			$self->{playlist} = $self->{playlist} + $#results + 1;
		}
	}
	return 1;
}

sub playlist
{
	my($self) = shift;
	$self->_connect;
	$self->_get_playlist if !defined($playlist[0]);
	return \@playlist;
}

sub get_title
{
	my($self,$song) = @_;
	$self->_connect;
	my $info;
	$info = $self->{song} unless !defined($self->{song}) || $self->{song} =~ /^\D+$/;
	$info = $song unless !defined($song) || $song =~ /^\D+$/;
	return 'n/a' if !defined($info);
	return '' if !defined($self->{playlistlength}) || $info eq 'false' || ($info ne 'false' && $self->{playlistlength}-1 < $info);
	my %metadata = $self->get_song_info($info);
	return $metadata{'Artist'}.' - '.$metadata{'Title'} if $metadata{'Artist'} && $metadata{'Title'};
	return $metadata{'file'};
}

sub get_time_format
{
  my($self) = shift;
  return '' if !defined($self->{playlistlength}) || !defined($self->{song});
	$self->_connect;
  my($psf,$tst) = split /:/, $self->{'time'};
  return sprintf("%d:%02d/%d:%02d",
       ($psf / 60), # minutes so far
       ($psf % 60), # seconds - minutes so far
       ($tst / 60), # minutes total
       ($tst % 60));# seconds - minutes total
}

1;
