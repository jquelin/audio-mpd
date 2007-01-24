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
		'IO::Socket'	=> '1.00',
		'Test' 			=> '1.00',
	},
);

$build->create_build_script();
