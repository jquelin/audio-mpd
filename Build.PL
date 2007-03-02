#!/usr/bin/perl
#
#

use Module::Build;
use Module::Build::Compat;


my $build = Module::Build->new
(
	module_name => 'Audio::MPD',
	license => 'gpl',
	build_requires => {
		'Module::Build' => '0.20'
	},

	create_makefile_pl => 'passthrough',

	requires => {
        'Class::Accessor' => '0',
		'IO::Socket'	=> '0',
		'Test' 			=> '0',
	},
);

$build->create_build_script();
