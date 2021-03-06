package Genome::Model::Tools::Sam::Readcount;

use strict;
use warnings;

use Genome;
use File::Touch qw(touch);

my $DEFAULT_VER = '0.6';

class Genome::Model::Tools::Sam::Readcount {
    is  => 'Command',
    has_optional_input => [
        use_version => {
            is  => 'Version',
            doc => "bam-readcount version to be used.",
            default_value => $DEFAULT_VER,
        },
        bam_file => {
            is => 'String',
            doc => "The bam file from which to obtain readcounts",
        },
        output_file => {
            is => 'String',
            doc => "The output file containing readcounts",
            is_output => 1,
        },
        minimum_mapping_quality => {
            is => 'Integer',
            default => 0,
            doc => "filter reads with mapping quality less than this. This is the -q parameter.",
        },
        reference_fasta => {
            is => 'String',
            doc => "The reference fasta to be used. This corresponds to the -f parameter.",
        },
        region_list => {
            is => 'String',
            doc => "list of regions to report readcounts within. This should be in a tab delimited format with 'chromosome start stop'. This is the -l parameter.",
        },
        minimum_base_quality => {
            is => 'Integer',
            default => 0,
            doc => "don't include reads where the base quality is less than this. This is the -b parameter. This is only available in versions 0.3 and later.",
        },
        comma_separated_format => {
            is  => 'Boolean',
            default => 0,
            doc => "report the mapping qualities as a comma separated list. This is the -d parameter. This is only available in versions 0.3 to 0.4.",
        },
        max_count => {
            is  => 'Integer',
            doc => "max depth to avoid excessive memory. This is the -d parameter in version 0.5.",
        },
        per_library => {
            is  => 'Bool',
            default => 0,
            doc => "report results per library. This is the -p parameter in version 0.5.",
        },
        insertion_centric => {
            is  => 'Bool',
            default => 0,
            doc => "do not include reads containing insertions after the current position in per-base counts. This is the -i parameter in version 0.5.",
        },
    ],
    doc => "Tool to get readcount information from a bam",
};

sub help_synopsis {
    "gmt readcount bam --minimum-base-quality 15 --use-version 0.4 --reference-fasta /path/to/fasta.fa --region-list /path/to/regions --bam-file /path/to/file.bam";
}

sub help_detail {
    "used to get readcount information from a bam";
}

sub default_version {
    return $DEFAULT_VER;
}

sub readcount_path {
    my $self = shift;
    my $version = $self->use_version || "";

    # This is hacky but the original bam-readcount version in use, 0.2, is simply deployed as "bam-readcount"
    my $path;
    if ($version eq "0.2") {
        $path = "/gsc/bin/bam-readcount";
    } 
    else {
        $path = "/usr/bin/bam-readcount$version";
    }

    if (! -x $path) {
        die $self->error_message("Failed to find executable bam-readcount version $version at $path!");
    }
    return $path;
}

sub execute {
    my $self = shift;
    my $version = $self->use_version || "";

    my $bam = $self->bam_file;
    unless (-s $bam) {
        die $self->error_message("Bam file $bam does not exist or does not have size");
    }
    my $reference = $self->reference_fasta;
    unless (-s $reference) {
        die $self->error_message("Reference fasta $reference does not exist or does not have size");
    }

    my $output_file = $self->output_file;
    Genome::Sys->validate_file_for_writing($output_file);

    my $region_file = $self->region_list;
    unless (-s $region_file) {
        $self->warning_message("Region list provided $region_file does not exist or does not have size. Skipping run and touching output ($output_file).");
        touch($output_file);
        return 1;
    }

    my $command = $self->readcount_path . " $bam -f $reference -l $region_file";
    if ($self->minimum_mapping_quality) {
        $command .= " -q " . $self->minimum_mapping_quality;
    }
    if ($self->minimum_base_quality) {
        $command .= " -b " . $self->minimum_base_quality;
    }
    if ($self->comma_separated_format && ($version eq "0.3" or $version eq "0.4")) {
        $command .= " -d";
    }
    if(defined $self->max_count) {
        $command .= " -d " . $self->max_count;
    }
    if($self->per_library) {
        $command .= " -p";
    }
    if($self->insertion_centric) {
        $command .= " -i";
    }
    if($version >= "0.5") {
        $command .= " -w 1";    # suppress error messages to a single report
    }

    if ($output_file =~ /[\(\)]/) {
        $output_file =~ s{\(}{\\(}g;
        $output_file =~ s{\)}{\\)}g;
    }

    Genome::Sys->shellcmd(
        cmd => "$command > $output_file",
        input_files => [$bam, $reference, $region_file],
        output_files => [$output_file],
        allow_zero_size_output_files => 1,
    );
    $self->debug_message('Done running BAM Readcounts.');

    return 1;
}

1;

