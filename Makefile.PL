#!perl
#
# This file is part of Audio::MPD
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

require 5.8.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Audio::MPD',
    VERSION_FROM        => 'lib/Audio/MPD.pm',
    ABSTRACT_FROM       => 'lib/Audio/MPD.pm',
    EXE_FILES           => [ 'bin/mpd-dynamic' ],
    PREREQ_PM => {
        'Audio::MPD::Common' => 0,
        'Class::Accessor'    => 0,
        'Encode'             => 0,
        'IO::Socket'         => 0,
        'Readonly'           => 0,
        'Scalar::Util'       => 0,
        'Test::More'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [ 'Audio-MPD-*', '*~', '*/*~', '*/*/*~',
						  '*/*/*/*~', '*/*/*/*/*~' ] },
);
