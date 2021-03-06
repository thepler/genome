package Genome::Test::Factory::Taxon;
use base qw(Genome::Test::Factory::Base);

use strict;
use warnings;
use Genome;

our @required_params = qw(name domain);

sub generate_obj {
    my $self = shift;
    return Genome::Taxon->create(@_);
}

sub create_name {
    return Genome::Test::Factory::Util::generate_name('taxon_name');
}

sub create_domain {
    return Genome::Test::Factory::Util::generate_name('domain');
}

1;
