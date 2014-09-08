#!/usr/bin/perl -w

use strict;

my $name=""; 
while (<>) {
    s/[\r\n]+//g;
    my ($n, $e)=split /\t/,$_;
    if ($e){
	if ($name && $n ne $name) { 
	    print "$name\t\n"; 
	}else{ 
	    print $_, "\n";
	} 
	$name='';
    } else {
	$name=$n;
    }
    print STDERR  "line: $_ lastname: $name n: $n e: $e\n"; 
}
