#!perl
#

require 5.8.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Audio::MPD',
    VERSION_FROM        => 'lib/Audio/MPD.pm',
    ABSTRACT_FROM       => 'lib/Audio/MPD.pm',
    EXE_FILES           => [],
    PREREQ_PM => {
        'Class::Accessor' => 0,
        'IO::Socket'	  => 0,
        'Readonly'  	  => 0,
        'Scalar::Util'    => 0,
        'Test::More'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [ 'Audio-MPD-*', '*~', '*/*~', '*/*/*~',
						  '*/*/*/*~', '*/*/*/*/*~' ] },
);
