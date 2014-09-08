#!/usr/bin/perl -w

while(my $line=<>){

    my @line= split /\t/, $line;
    if (scalar @line >11){
	my $staff=$line[10];
	$staff=~s/,([^ ])/\:$1/g;
	my @staff=split/:/,$staff;
	foreach my $s (@staff) {
	    print join("\t",@line[0 .. 9],$s,@line[11 .. 13])
	}
    }
}
