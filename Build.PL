
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::Corpus::Audio::MPD" => "1.113282",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "class to talk to MPD (Music Player Daemon) servers",
  "dist_author" => [
    "Jerome Quelin"
  ],
  "dist_name" => "Audio-MPD",
  "dist_version" => "1.120610",
  "license" => "perl",
  "module_name" => "Audio::MPD",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Audio::MPD::Common::Item" => 0,
    "Audio::MPD::Common::Output" => 0,
    "Audio::MPD::Common::Stats" => 0,
    "Audio::MPD::Common::Status" => 0,
    "DB_File" => 0,
    "Encode" => 0,
    "Getopt::Euclid" => 0,
    "IO::Socket::IP" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Has::Sugar" => 0,
    "MooseX::SemiAffordanceAccessor" => 0,
    "Proc::Daemon" => 0,
    "Time::HiRes" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/mpd-dynamic",
    "bin/mpd-rate"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
