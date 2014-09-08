#!/usr/bin/perl -w

use strict;
use Getopt::Long;



my @currec=();

my $intable=0;
my $linecount=0;
my $currday='';
while (<>){
    $linecount++;
    if ($_=~m/<table/){
	$intable=1;
    } elsif ($_=~m!</table!){
	$intable=0;
    } elsif ($_=~m! >(.*day)</s!){
	$currday=$1;
	print STDERR "CURRENT DAY $currday\n";
    }
    next unless $intable;
    if ($_ =~ m/^<tr/){
	# new record
	@currec=($currday);

    } elsif ($_ =~ m!^<td>(.*)</td>!){
	push @currec, $1;
    } elsif ($_ =~ m!^</tr>!){
	#join records
	if (@currec >3){
	    print join("\t", @currec),"\n";
	}
    }
}

print STDERR "$linecount\n";
