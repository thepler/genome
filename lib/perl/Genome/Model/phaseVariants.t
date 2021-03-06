#!/usr/bin/env genome-perl

use strict;
use warnings;
#use Genome::Model::phaseVariants;
use above "Genome"; 
use Test::More tests => 1;
use File::Basename;
#use File::Spec my $dirName = dirname(__FILE__);
use File::Temp qw(tempfile);

#print($INC{"phaseVariants.pm"}, "\n");

my $plot = Genome::Model::phaseVariants->create(
                                                         distance  => 700,
                                                         command => "C",
							 vcfFile => "/gscuser/cfederer/Documents/mysnvs.vcf",
                                                         bamFile => "/gscuser/cfederer/Documents/p53.bam",
                                                         chromosome => 17,
							 sample => "none",
							 relax => "false", 
							 snvs => "7579646T7579653C", 
	 						 printReads => "t", 
							 outFile => "/gscuser/cfederer/git/genome/lib/perl/Genome/Model/phaseVariantsOutPut.txt"
                                                        );
ok($plot->execute,'Executed');
                                                  
