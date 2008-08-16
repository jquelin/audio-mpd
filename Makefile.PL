#!perl
#
# This file is part of Audio::MPD
# Copyright (c) 2007-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

BEGIN { require 5.008; }
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Audio::MPD',
    VERSION_FROM        => 'lib/Audio/MPD.pm',
    ABSTRACT_FROM       => 'lib/Audio/MPD.pm',
    EXE_FILES           => [ 'bin/mpd-dynamic' ],
    PREREQ_PM => {
        'Audio::MPD::Common'    => 0,
        'Class::Accessor::Fast' => 0,
        'DB_File'               => 0, # for mpd-dynamic
        'Encode'                => 0,
        'Getopt::Euclid'        => 0, # for mpd-dynamic
        'IO::Socket'            => 0,
        'Proc::Daemon'          => 0, # for mpd-dynamic
        'Readonly'              => 0,
        'Scalar::Util'          => 0,
        'Test::More'            => 0,
        'Time::HiRes'           => 0, # for mpd-dynamic
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [ 'Audio-MPD-*', 'MANIFEST.bak',
						  map { ( '*/' x $_ ) . '*~' } 0..6 ] },
);
