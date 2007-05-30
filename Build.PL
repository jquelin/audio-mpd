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
	license             => 'gpl',
    dist_version_from   => 'lib/Audio/MPD.pm',
    add_to_cleanup => [ 'Audio-MPD-*', '*~', '*/*~', '*/*/*~',
                        '*/*/*/*~', '*/*/*/*/*~' ],
    script_files => [ 'bin/mpd-dynamic' ],
    build_requires => {
        'Test::More'    => 0,
        'perl'          => '5.8.0',
    },
    requires => {
        'Audio::MPD::Common' => 0,
        'Class::Accessor'    => 0,
        'IO::Socket'         => 0,
        'Encode'             => 0,
        'Readonly'           => 0,
        'Scalar::Util'       => 0,
        'perl'               => '5.8.0',
    },
);

$builder->create_build_script();
