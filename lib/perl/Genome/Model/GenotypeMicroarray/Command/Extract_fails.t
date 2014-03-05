#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
};

use above 'Genome';

use Test::More;

use_ok('Genome::Model::GenotypeMicroarray::Command::Extract') or die;
use_ok('Genome::Model::GenotypeMicroarray::Test') or die;

my $build = Genome::Model::GenotypeMicroarray::Test::example_build();
my $variation_list_build = $build->dbsnp_build;
my $instrument_data = $build->instrument_data;

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
my $output_tsv = $tmpdir.'/genotypes';

# no source
my $extract = Genome::Model::GenotypeMicroarray::Command::Extract->create();
ok(!$extract->execute, 'failed to create command w/o source');
is($extract->error_message, 'No source given! Can be build, model, instrument data or sample.', 'correct error');

# instdata w/o variation list build
$extract = Genome::Model::GenotypeMicroarray::Command::Extract->create(
    instrument_data => $instrument_data,
);
ok(!$extract->execute, 'failed to create command from instdata w/o variation list build');
is($extract->error_message, 'Variation list build is required to get genotypes for an instrument data!', 'correct error');

# sample w/o variation list build
$extract = Genome::Model::GenotypeMicroarray::Command::Extract->create(
    sample => $instrument_data->sample,
);
ok(!$extract->execute, 'failed to create command from instdata w/o variation list build');
is($extract->error_message, 'Variation list build is required to get genotypes for a sample!', 'correct error');

done_testing();