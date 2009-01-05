#!perl
#
# This file is part of Audio::MPD
# Copyright (c) 2007-2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use Module::Build;

my %script_requires = (
    'DB_File'        => 0,
    'Encode'         => 0,
    'Getopt::Euclid' => 0,
    'Proc::Daemon'   => 0,
    'Time::HiRes'    => 0,
);
my %requires = (
    %script_requires,
    'perl'                  => '5.008',
    'Audio::MPD::Common'    => 0,
    'Class::Accessor::Fast' => 0,
    'Encode'                => 0,
    'IO::Socket'            => 0,
    'Readonly'              => 0,
    'Scalar::Util'          => 0,
);
my %build_requires = (
    %requires,
    'Test::More' => 0,
);
my %recommends = (
    'Test::Pod'           => 0,
    'Test::Pod::Coverage' => 0,
);

my $builder = Module::Build->new (
	module_name         => 'Audio::MPD',
	license             => 'perl',
    dist_version_from   => 'lib/Audio/MPD.pm',
    script_files        => [ 'bin/mpd-dynamic' ],
    build_requires      => \%build_requires,
    requires            => \%requires,
    recommends          => \%recommends,
    add_to_cleanup      => [
        'Audio-MPD-*', 'MANIFEST.bak',
        map { ( '*/' x $_ ) . '*~' } 0..6 ],
);

$builder->create_build_script();
