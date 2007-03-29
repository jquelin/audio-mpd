#!perl
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
        'Class::Accessor' => 0,
        'IO::Socket'	  => 0,
        'Readonly'  	  => 0,
        'Scalar::Util'    => 0,
        'perl'            => '5.8.0',
    },
);

$builder->create_build_script();
