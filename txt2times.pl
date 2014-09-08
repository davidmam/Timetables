#!/usr/bin/perl -w

use strict;
no strict "subs";

use Getopt::Long;

my $infile='';
my $outfile='';

GetOptions("infile=s"=>\$infile,
	   "outfile=s"=>\$outfile);

unless ($infile && -e $infile) {
    die "could not find infile $infile\n";
}

open IN, $infile or die "Could not open infile $infile: $!\n";

unless ($outfile) {
    $outfile=$infile.".out.txt";
}

open OUT, ">$outfile" or die "could not open output file $outfile: $!\n";

my $line='';
for (my $i=0; $i<4; $i++){
 $line=<IN>;
}
$line=~s/[\r\n]*//g;
my @header=split/\t/, $line;
my $fields=scalar @header;

while ($line=<IN>){
    if ($line=~m/^-------/) {last;}
    my @F = split /\t/, $line;
    if (scalar @F < $fields){
	$line=~s/[\r\n]*//g;
	$line.=<IN>;
    }
    if ($F[0]){print OUT $line;}
}
close IN;
close OUT;
