#!/usr/bin/perl -w

use Date::Calc qw(Add_Delta_Days);
use Getopt::Long;

my $infile='';
my $outfile='';
my $sem1week=1;
my $sem1date="15 Sep 2014";
my $sem2week=15;
my $sem2date="19 Jan 2015";
my $startdate=$sem1date;
my $startweek=$sem1week;
GetOptions( 'infile=s'=>\$infile,
	    'outfile=s'=>\$outfile,
	    'startweek=i'=>\$startweek,
	    'startdate=s'=>\$startdate
    );

open (INFILE, $infile) or die "error opening input file $infile: $!\n";
open (OUTFILE, ">$outfile") or die "error opening output file $outfile: $!\n";

my $header=<INFILE>;
$header=~s/[\r\n]//g;
my @header=split(/\t/, $header);
shift @header;
unshift @header,  "Title";
unshift @header,  "Activity";
unshift @header, "Semester";
unshift @header, "Module";
push @header,"Week",  "Date";
print OUTFILE join("\t", @header),"\n";

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

my %days=('Monday'=>0, 'Tuesday'=>1,'Wednesday'=>2, 'Thursday'=>3, 'Friday'=>4);

my @months= qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @date=split/ /,$startdate;
while (my $line=<INFILE>) {
    $line=~s/[\r\n]//g;
    my @items=split /\t/, $line;
    my @det=split/[\/-]/, $items[0], 4;
    while (@det <4){ push @det, "";}
    splice(@items,0,1,@det);
    
    my $count=0;
    foreach $p (@items){
	print STDERR "$count\t$p\n";
	$count++;
    }
    
    my $weeks=$items[8];
    my @weeklist=();
    foreach my $w (split /, */, $weeks){
	print STDERR "processing week $w\n";
	my($sw, $ew)=split/-/, $w;
	if ($ew){
	    for (my $tw=$sw; $tw<=$ew; $tw++){
		push @weeklist, $tw;
	    }
	} else {
	    push @weeklist, $sw;
	}
    }
    print STDERR join(":",@weeklist),"\n";
    foreach my $wd (@weeklist){
	print STDERR "$wd\n";
	if ($wd>=$sem2week){
	    $startweek=$sem2week;
	    $startdate=$sem2date;
	}else{
	    $startweek=$sem1week;
	    $startdate=$sem1date;
	}
	@date=split/ /,$startdate;
	my @id=($date[2], $months{$date[1]},$date[0]);
	if ($wd>$startweek || $items[11] ne 'Monday' ){
	    print STDERR "adding days to @id\n";
	    @id=Add_Delta_Days($date[2], $months{$date[1]},$date[0], $days{$items[11]}+7*($wd-$startweek));
	} 
	print STDERR "id is @id\n";
	

	print OUTFILE join("\t", @items, $wd, join(' ', $id[2], $months[$id[1]-1], $id[0])),"\n";
    }
}
