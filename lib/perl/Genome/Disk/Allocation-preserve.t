#!/usr/bin/env genome-perl

BEGIN { 
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use strict;
use warnings;

use above "Genome";
use Test::More;
use File::Temp 'tempdir';
use File::Basename;
use Filesys::Df qw();

$DB::stopper = 0;

use_ok('Genome::Disk::Allocation') or die;
use_ok('Genome::Disk::Volume') or die;

my $volume = create_test_volume();

# Make test allocation
my $allocation = Genome::Disk::Allocation->create(
    disk_group_name => $volume->disk_group_names,
    allocation_path => 'testing123',
    owner_class_name => 'UR::Value',
    owner_id => 'foo',
    kilobytes_requested => 1,
);
ok($allocation, 'created test allocation on non-archive disk');
is($allocation->mount_path, $volume->mount_path, 'allocation on expected volume');

# Make a few testing files in the allocation directory
my @files = qw/ a.out b.out c.out /;
my @dirs = qw/ test /;
for my $file (@files) {
    my $path = $allocation->absolute_path . "/$file";
    system("touch $path");
    ok(-e $path, "created test file $path");
}
for my $dir (@dirs) {
    my $path = $allocation->absolute_path . "/$dir";
    system("mkdir $path");
    ok(-d $path, "created test dir $path");
}

# Make sure we can read and write to files in the allocation directory
for my $file (@files) {
    my $path = join('/', $allocation->absolute_path, $file);
    ok(-r $path, "can read $path");
    ok(-w $path, "can write to $path");
}

ok(!$allocation->preserved, 'allocation is not currently preserved');
$DB::stopper = 1;
ok($allocation->preserved(1), 'preserved allocation');
ok($allocation->preserved, 'allocation is now preserved');

done_testing();

sub create_test_volume {
    my $test_dir_base = "$ENV{GENOME_TEST_TEMP}/";
    my $test_dir = tempdir(
        'allocation_testing_XXXXXX',
        DIR => $test_dir_base,
        UNLINK => 1,
        CLEANUP => 1,
    );
    $Genome::Disk::Allocation::CREATE_DUMMY_VOLUMES_FOR_TESTING = 0;

    my $volume_path = tempdir(
        "test_volume__XXXXXXX",
        DIR => $test_dir,
        CLEANUP => 1,
        UNLINK => 1,
    );
    my $volume = Genome::Disk::Volume->create(
        hostname => 'foo',
        physical_path => 'foo/bar',
        mount_path => $volume_path,
        total_kb => Filesys::Df::df($volume_path)->{blocks},
        disk_status => 'active',
        can_allocate => '1',
    );
    ok($volume, 'made testing volume') or die;

    my $group = Genome::Disk::Group->create(
        disk_group_name => 'testing_group',
        permissions => '755',
        sticky => '1',
        subdirectory => 'testing',
        unix_uid => 0,
        unix_gid => 0,
    );
    ok($group, 'successfully made testing group') or die;
    push @Genome::Disk::Allocation::APIPE_DISK_GROUPS, $group->disk_group_name;

    my $assignment = Genome::Disk::Assignment->create(
        dg_id => $group->id,
        dv_id => $volume->id,
    );
    ok($assignment, 'assigned volume to testing group');
    system("mkdir -p " . join('/', $volume->mount_path, $volume->groups->subdirectory));

    return $volume;
}
