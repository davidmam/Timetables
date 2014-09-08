#!/usr/bin/perl -w

use Date::Calc qw(Add_Delta_Days);

my $header=<>;
my @header=split(/\t/, $header);
unshift @header, 'item';
unshift @header, 'Semester';
unshift @header, 'Module';

print join("\t", @header);

my %months=(
'Jan'=>1,
'Feb'=>2,
'Mar'=>3,
'Apr'=>4,
'May'=>5,
'Jun'=>6,
'Jul'=>7,
'Aug'=>8,
'Sep'=>9,
'Oct'=>10,
'Nov'=>11,
'Dec'=>12
);

my @months= qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
while (my $line=<>) {
    $line=~s/[\r\n]//g;
    my @items=split /\t/, $line;
    my @det=split/-/, $items[0], 4;
    splice(@items,0,1,@det);
    my @date=split/ /,$items[10];
    
    
    my $weeks=$items[8];
    my @weeklist=();
    foreach my $w (split /,/, $weeks){
	my($sw, $ew)=split/-/, $w;
	if ($ew){
	    for (my $tw=$sw; $tw<=$ew; $tw++){
		push @weeklist, $tw;
	    }
	} else {
	    push @weeklist, $sw;
	}
    }
    my $fw=$weeklist[0];
    foreach my $wd (@weeklist){
	my @id=($date[2], $months{$date[1]},$date[0]);
	if ($wd>$fw){
	    @id=Add_Delta_Days($date[2], $months{$date[1]},$date[0], 7*($wd-$fw));
	} 

	print join("\t", @items[0..10], $wd, join(' ', $id[2], $months[$id[1]-1], $id[0])),"\n";
    }
}

