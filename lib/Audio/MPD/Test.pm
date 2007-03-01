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

package Audio::MPD::Test;

use strict;
use warnings;

use Exporter;
use FindBin     qw[ $Bin ];
use Readonly;


use base qw[ Exporter ];
our @EXPORT = qw[ start_test_mpd stop_test_mpd ];


Readonly my $TEMPLATE => "$Bin/mpd-test/mpd.conf.template";
Readonly my $CONFIG   => "$Bin/mpd-test/mpd.conf";

{ # this will be run when Audio::MPD::Test will be use-d.
    _customize_test_mpd_configuration();
    my $restart = _stop_user_mpd_if_needed();
    start_test_mpd();

    END {
        stop_test_mpd();
        return unless $restart;            # no need to restart
        system 'mpd 2>/dev/null' if $restart;     # restart user mpd
        sleep 1;                           # wait 1 second to let mpd start.
    }
}


#--
# public subs


#
# start_test_mpd()
#
# Start the fake mpd, and die if there were any error.
#
sub start_test_mpd {
    system( "mpd $CONFIG 2>/dev/null" ) == 0
        or die "could not start fake mpd: $?\n";
    sleep 1;   # wait 1 second to let mpd start.
}


#
# stop_test_mpd()
#
# Kill the fake mpd.
#
sub stop_test_mpd {
    system "mpd --kill $CONFIG 2>/dev/null";
    sleep 1;   # wait 1 second to free output device.
}


#--
# private subs


#
# _customize_test_mpd_configuration()
#
# Create a fake mpd configuration file, based on the file mpd.conf.template
# located in t/mpd-test. The string PWD will be replaced by the real path -
# ie, where the tarball has been untarred.
#
sub _customize_test_mpd_configuration {
    # open template and config.
    open my $in,  '<',  $TEMPLATE or die "can't open [$TEMPLATE]: $!\n";
    open my $out, '>',  $CONFIG   or die "can't open [$CONFIG]: $!\n";

    # replace string and fill in config file.
    while ( defined( my $line = <$in> ) ) {
        $line =~ s!PWD!$Bin/mpd-test!;
        print $out $line;
    }

    # clean up.
    close $in;
    close $out;
}


#
# my $was_running = _stop_user_mpd_if_needed()
#
# This sub will check if mpd is currently running. If it is, force it to
# a full stop (unless MPD_TEST_OVERRIDE is not set).
#
# In any case, it will return a boolean stating whether mpd was running
# before forcing stop.
#
sub _stop_user_mpd_if_needed {
    # check if mpd is running.
    my $is_running = grep { /mpd$/ } qx[ ps -e ];

    return 0 unless $is_running; # mpd does not run - nothing to do.

    # check force stop.
    die "mpd is running\n" unless $ENV{MPD_TEST_OVERRIDE};
    system( 'mpd --kill 2>/dev/null') == 0 or die "can't stop user mpd: $?\n";
    sleep 1;  # wait 1 second to free output device
    return 1;
}


1;

__END__

=head1 NAME

Audio::MPD::Test - automate launching of fake mdp for testing purposes


=head1 SYNOPSIS

    use Audio::MPD::Test; # die if error
    [...]
    stop_fake_mpd();


=head1 DESCRIPTION

=head2 General usage

This module will try to launch a new mpd server for testing purposes. This
mpd server will then be used during Audio::MPD tests.

In order to achieve this, the module will create a fake mpd.conf file with
the correct pathes (ie, where you untarred the module tarball). It will then
check if some mpd server is already running, and stop it if the
MPD_TEST_OVERRIDE environment variable is true (die otherwise). Last it will
run the test mpd with its newly created configuration file.

Everything described above is done automatically when the module is C<use>-d.


Once the tests are run, the mpd server will be shut down, and the original
one will be relaunched (if there was one).

Note that the test mpd will listen to C<localhost>, so you are on the safe
side. Note also that the test suite comes with its own ogg files - and yes,
we can redistribute them since it's only some random voice recordings :-)


=head2 Advanced usage

In case you want more control on the test mpd server, you can use the
following public methods:

=over 4

=item start_test_mpd()

Start the fake mpd, and die if there were any error.

=item  stop_test_mpd()

Kill the fake mpd.

=back

This might be useful when trying to test connections with mpd server.


=head1 COPYRIGHT AND LICENSE

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