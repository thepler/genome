package Genome::InstrumentData::Command::Import::WorkFlow::TransferFastqs;

use strict;
use warnings;

use Genome;

use Data::Dumper 'Dumper';
require File::Basename;
require List::MoreUtils;

class Genome::InstrumentData::Command::Import::WorkFlow::TransferFastqs { 
    is => 'Command::V2',
    has_input => [
        instrument_data => { 
            is => 'Genome::InstrumentData',
            is_output => 1,
            doc => 'Instrument data to transfer fastqs.',
        },
    ],
    #has_output => [ ],
    has_optional_transient => [
        source_files_and_read_counts => { is => 'Hash', default_value => {}, },
    ],
};

sub execute {
    my $self = shift;
    $self->status_message('Transfer fastqs...');

    # Transfer
    my $instrument_data = $self->instrument_data;
    my $original_data_path = $instrument_data->original_data_path;
    my @source_files = split(',', $original_data_path);
    $instrument_data->add_attribute(attribute_label => 'is_paired_end', attribute_value => ( @source_files == 2 ? 1 : 0 ));
    for my $source_file ( @source_files ) {
        my $transfer_ok = $self->_transfer_fastq($source_file);
        return if not $transfer_ok;
    }

    # Verify Read Counts
    my $read_counts_ok = $self->_verify_read_counts;
    return if not $read_counts_ok;

    $self->status_message('Transfer fastqs...done');
    return 1;
}

sub _transfer_fastq {
    my ($self, $fastq) = @_;

    my $dir = $self->instrument_data->data_directory;
    $self->status_message("Fastq: $fastq");
    my $fastq_base_name = File::Basename::basename($fastq);
    $fastq_base_name =~ s/\.gz$//;
    my $destination_file = $dir.'/'.$fastq_base_name;
    $self->status_message("Destination file: $destination_file");

    my $cmd;
    if ( $fastq =~ /^http/ ) {
        my $log = $dir.'/'.$fastq_base_name.'.log';
        $cmd = "wget -o $log -O - $fastq | zcat - | tee $destination_file";
    }
    elsif ( $fastq =~ /\.gz$/ ) { # zcat
        $cmd .= "zcat $fastq | tee $destination_file";
    }
    else {
        $cmd .= "tee $destination_file < $fastq";
    }

    my $line_count_file = $destination_file.'.count';
    $cmd .= " | wc -l > $line_count_file";
    $self->status_message("Line count file: $line_count_file");

    my $rv = eval{ Genome::Sys->shellcmd(cmd => $cmd); };
    if ( not $rv or not -s $destination_file ) {
        $self->error_message('Failed to transfer source file to tmp directory!');
        return;
    }

    my $read_count = $self->_get_read_count_from_line_count_file($line_count_file);
    return if not $read_count;
    $self->status_message("Read count: $read_count");
    my $source_files_and_read_counts = $self->source_files_and_read_counts;
    $source_files_and_read_counts->{$fastq} = $read_count;

    return 1;
}

sub _get_read_count_from_line_count_file {
    my ($self, $file) = @_;

    my $line_count = eval{ Genome::Sys->read_file($file); };
    if ( not defined $line_count ) {
        $self->error_message('Failed to open line count file! '.$@);
        return;
    }

    $line_count =~ s/\s+//g;
    if ( $line_count !~ /^\d+$/ ) {
        $self->error_message('Invalid line count! '.$line_count);
        return;
    }

    if ( $line_count == 0 ) {
        $self->error_message('Read count is 0!');
        return;
    }

    if ( $line_count % 4 != 0 ) {
        $self->error_message('Line count is not divisible by 4! '.$line_count);
        return;
    }

    return $line_count / 4;
}

sub _verify_read_counts {
    my $self = shift;
    $self->status_message('Verify read counts...');

    my $source_files_and_read_counts = $self->source_files_and_read_counts;
    $self->status_message('Source file read counts: '.Dumper($source_files_and_read_counts));
    my @read_counts = List::MoreUtils::uniq( values %$source_files_and_read_counts );
    if ( @read_counts > 1 ) {
        $self->error_message('Read counts are not the same for source fastqs!');
        return;
    }

    $self->status_message('Verify read counts...done');
    return 1;
}


1;
