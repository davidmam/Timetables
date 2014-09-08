#!/usr/bin/perl -w

use strict;

while (<>){
    my @F=split /\t/, $_;
    my $staff=$F[10];
    $staff=~s/, / /g;
    my @sm=split/,/, $staff;
    splice(@F, 10,1, $F[10],$F[10]); 
    foreach my $s (@sm){
	my ($ln, $fn)=split / /, $s, 2;
	splice(@F, 10, 2,$ln, $fn);
	print join("\t", @F);
    }
}
