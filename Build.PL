#!perl
#
# This file is part of Audio::MPD
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new (
	module_name         => 'Audio::MPD',
	license             => 'perl',
    dist_version_from   => 'lib/Audio/MPD.pm',
    add_to_cleanup => [ 'Audio-MPD-*', 'MANIFEST.bak',
                        map { ( '*/' x $_ ) . '*~' } 0..6 ],
    script_files => [ 'bin/mpd-dynamic' ],
    build_requires => {
        'Audio::MPD::Common' => 0,
        'Class::Accessor'    => 0,
        'Encode'             => 0,
        'IO::Socket'         => 0,
        'Readonly'           => 0,
        'Scalar::Util'       => 0,
        'Test::More'         => 0,
        'perl'               => '5.008',
    },
    requires => {
        'Audio::MPD::Common' => 0,
        'Class::Accessor'    => 0,
        'Encode'             => 0,
        'IO::Socket'         => 0,
        'Readonly'           => 0,
        'Scalar::Util'       => 0,
        'perl'               => '5.008',
    },
    recommends     => {
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
    },
);

$builder->create_build_script();
