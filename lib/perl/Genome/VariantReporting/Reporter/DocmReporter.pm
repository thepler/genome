package Genome::VariantReporting::Reporter::DocmReporter;

use strict;
use warnings;
use Genome;
use Genome::VariantReporting::BamReadcount::VafInterpreter;

class Genome::VariantReporting::Reporter::DocmReporter {
    is => [ 'Genome::VariantReporting::Reporter::WithHeaderAndSampleNames'],
    has => [
    ],
};

sub name {
    return 'docm';
}

sub requires_interpreters {
    return qw(position many-samples-vaf);
}

sub headers {
    my $self = shift;
    my @headers = qw/
        chromosome_name
        start
        stop
        reference
        variant
    /;
    push @headers, $self->_vaf_headers;

    return @headers;
}

sub _vaf_headers {
    my $self = shift;
    Genome::VariantReporting::BamReadcount::ManySamplesVafInterpreter->available_fields($self->sample_names);
}

1;
