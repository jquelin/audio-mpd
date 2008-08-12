#!perl
#
# This file is part of Audio::MPD
# Copyright (c) 2007-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use Test::More;
eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok();
