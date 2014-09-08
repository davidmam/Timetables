#!/usr/bin/perl -w

use strict;

my @currec=();

my $intable=0;
my $linecount=0;
my $day ='';
while (<>){
    $linecount++;
    if ($_=~m/<table/){
		$intable=1;
    } elsif ($_=~m!</table!){
		$intable=0;
    }
	if ($intable){
		if ($_ =~ m/^<tr/){
		# new record
		@currec=();

		} elsif ($_ =~ m!^<td>(.*)</td>!){
		push @currec, $1;
		} elsif ($_ =~ m!^</tr>!){
		#join records
			if ($currec[0] eq 'Activity'){
				push @currec, 'Day';
			}else{ 
				push @currec, $day;
			}
			print join("\t", @currec),"\n";
		}
	} else {
		if ($_=~m!<p><span class='labelone'>(.*day)</span></p>!){
			$day=$1;
		}
	}
}
print STDERR $linecount;
