#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use Test::More tests => 5;

use above 'Genome';

use_ok('Genome::Model::Tools::Varscan');

ok(Genome::Model::Tools::Varscan->path_for_latest_version, 'got a latest version');

my $default_version = Genome::Model::Tools::Varscan->default_version;
ok($default_version, 'got a default version');

my $default_path = Genome::Model::Tools::Varscan->path_for_version;
ok($default_path, 'got a default path');

is(Genome::Model::Tools::Varscan->path_for_version($default_version), $default_path, 'default path is the path for the default version');
