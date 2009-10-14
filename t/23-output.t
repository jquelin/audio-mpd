#!perl

use strict;
use warnings;

use Audio::MPD;
use Test::More;

# are we able to test module?
eval 'use Audio::MPD::Test';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;

plan tests => 5;
my $mpd = Audio::MPD->new;


#
# testing absolute volume.
my $oldvol = $mpd->status->volume; # saving volume.
$mpd->volume(10); # init to sthg that we know
$mpd->volume(42);
is( $mpd->status->volume, 42, 'setting volume' );

#
# testing positive relative volume.
$mpd->volume('+9');
is( $mpd->status->volume, 51, 'increasing volume' );

#
# testing negative relative volume.
$mpd->volume('-4');
is( $mpd->status->volume, 47, 'decreasing volume' );
$mpd->volume($oldvol);  # resoring volume.

#
# testing disable_output.
$mpd->playlist->add( 'title.ogg' );
$mpd->playlist->add( 'dir1/title-artist-album.ogg' );
$mpd->playlist->add( 'dir1/title-artist.ogg' );
$mpd->play;
$mpd->output_disable(0);
sleep(1);
SKIP: {
    # FIXME?
    my $error = $mpd->status->error;
    skip "detection method doesn't always work - depends on timing", 1
        unless defined $error;
    like( $error, qr/^problems/, 'disabling output' );
}

#
# testing enable_output.
$mpd->output_enable(0);
sleep(1);
$mpd->play; $mpd->pause;
is( $mpd->status->error, undef, 'enabling output' );


exit;
