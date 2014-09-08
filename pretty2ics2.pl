#!/usr/bin/perl -w

use strict;

# Script to convert tabular format into staff (by staff member) and student (by module) ICS files.

use DateTime;
use Getopt::Long;

my $inputfile=''; # tabular file from prettyprocess
my $managersfile=''; # file detailing module codes and module manager name/email
my $stafflist=''; # file listing staff members and email addresses.
my $bymodule=0; # flag for producing module output
my $bystaff=0; # flag for producing staff output.
my $outdir='.'; # location for output files.

my %modulemanagers=();
my %staffnames=();

GetOptions( "input=s"=>\$inputfile,
	    "managers=s"=>\$managersfile,
	    "staff=s"=>\$stafflist,
	    "module"=>\$bymodule,
	    "individual"=>$bystaff,
	    "outdir=s"=>\$outdir
    );

if (!($bymodule || $bystaff)){
    $bymodule=1;
    $bystaff=1;
}

unless ($inputfile && -e $inputfile){
    die "a valid input file must be specified\n";
}
if ($outdir && -e $outdir && ! -d $outdir){
    die "$outdir is not a directory.\n";
} elsif ($outdir && ! -e $outdir) {
    mkdir $outdir;
}


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


open(STAFF, $stafflist) or die "Could not open staff list $stafflist: $!\n";
open(MANAGERS, $managersfile) or die "Could not open module managers file $managersfile: $!\n";

my $line='';
while ( $line=<STAFF>){
    $line=~s/[\r\n]//g;
    my ($cn, $email)=split/\t/, $line;
    $staffnames{$cn}=$email;
}

close STAFF;

while ($line=<MANAGERS>){
    $line=~s/[\r\n]//g;
    my ($module, $cn)=split/\t/, $line;
    $modulemanagers{$module}=$cn;
}

close MANAGERS;
foreach my $m (keys %modulemanagers){
    print STDERR "$m $modulemanagers{$m}\n";
}

my %eventsbymodule=();

my %eventsbystaff=();

open(INPUT, $inputfile) or die "cannot open input file $inputfile: $!\n";

$line=<INPUT>; # skip header line.
my $eventserial=0;
while ($line=<INPUT>){
    $eventserial++;
    $line=~s/[\r\n]//g;
    my @F=split/\t/, $line;
    my $modname=$F[1];
    $line=$line."\t$eventserial";
    unless(exists($eventsbymodule{$modname})){
	$eventsbymodule{$modname}=[];
    }
    push @{$eventsbymodule{$modname}}, $line;
    my $names=$F[10];
    $names=~s!,([^ ])!/$1!g;
    foreach my $s (split (/\//, $names)){
	my $name=join(" ", split /, /,$s);
	unless (exists($staffnames{$name})){
	    warn "No staff entry for $name\n";
	    next;
		}
	unless( exists($eventsbystaff{$name})){
	    $eventsbystaff{$name}={$modname=>[]};
	}
	unless( exists($eventsbystaff{$name}{$modname})){
	    $eventsbystaff{$name}{$modname}=[];
	}
	push @{$eventsbystaff{$name}{$modname}}, $line;
	#print STDERR "NAME $name\n";
    }
    #print STDERR "NAMES $names\n";
}

		

# print out by module - should be METHOD:PUBLISH

my $nowdate=DateTime->now();
my $dtstamp=$nowdate->strftime("%Y%m%dT%H%M00Z");

if ($bystaff){
    foreach my $s (keys %eventsbystaff){
	my $sn=$s;
	$sn=~s/ /_/g;
	open (MODULE, ">$outdir/$sn.ics") or die " could not create output file $outdir/$sn.ics: $!\n";
	open (MODULETEXT, ">$outdir/$sn.txt") or die " could not create output file $outdir/$sn.txt: $!\n";

	#print STDERR "KEYNAME $s\n";

	foreach my $m (keys %{$eventsbystaff{$s}}){
	    # print VCALENDAR header
	    print MODULE "BEGIN:VCALENDAR\nPRODID:David's useful timetabler v1\nVERSION:2.0\nMETHOD:REQUEST\n";
	    print MODULETEXT "Calendar for $m\n\n";

	    foreach my $e (@{$eventsbystaff{$s}{$m}}){
		print MODULE "BEGIN:VEVENT\n";
		my %eventdetails=(
		    #DTSTAMP=>"DTSTAMP:$dtstamp",
		    DTSTART=>'',ORGANIZER=>'',SUMMARY=>'',UID=>'',CATEGORIES=>'',CONTACT=>'',DTEND=>'',ATTENDEE=>[],LOCATION=>''
		    );
		$e=~s/[\n\r]//g;
		my @F=split /\t/, $e;
		my $orgname="Life Sciences School Office";
		my $org='schooloffice-ls@dundee.ac.uk';
		if (exists($modulemanagers{$F[1]})){
		    $orgname=$modulemanagers{$F[1]};
		    $org=$staffnames{$orgname};
		}
		#print STDERR "$orgname $org\n";
		my $mm=join(" ", reverse(split(/ /, $orgname)));
		$eventdetails{ORGANIZER}="ORGANIZER;CN=\"Module Manager: $mm\":mailto:$org";
		my $level=substr($F[1],2,1);
		$eventdetails{CONTACT}="CONTACT;CN=\"Life Sciences School Office\":mailto:lsuglevel${level}\@dundee.ac.uk";
		$eventdetails{CATEGORIES}="CATEGORIES:$F[5]";
		my $date=$F[13];
		my ($D,$m,$Y)=split / /, $date;
		my $M=$months{$m};
		my ($starth, $startm)=split /:/,$F[6];
		$starth=$starth-isBST($date);
		my ($endh, $endm)=split /:/,$F[7];
		$endh=$endh-isBST($date);
		my $dtstart=sprintf("%4d%02d%02dT%02d%02d00Z",$Y,$M,$D,$starth,$startm);
		my $dtend=sprintf("%4d%02d%02dT%02d%02d00Z",$Y,$M,$D,$endh,$endm);
		$eventdetails{DTSTART}="DTSTART:$dtstart";
		$eventdetails{DTEND}="DTEND:$dtend";
		$eventdetails{UID}="UID:$F[1]-$Y-$F[14]\@dundee.ac.uk";
		$eventdetails{LOCATION}="LOCATION:$F[11]";
		$eventdetails{SUMMARY}="SUMMARY:$F[1] $F[3]";
		my $staff=$F[10];
		$staff=~s/, / /g;
		#print STDERR "STAFF $staff\n";
		my @estaff=split/[,\/]/, $staff;
		foreach my $sm (@estaff){
		    my $scn=join(" ", reverse(split(/ /,$sm)));
		    if (exists($staffnames{$sm})){
			push @{$eventdetails{ATTENDEE}}, "ATTENDEE;RSVP=FALSE;CN=\"$scn\":mailto:$staffnames{$sm}";
			#print STDERR "$sm\n";
		    }
		}
		foreach my $ed (keys %eventdetails){
		    if ($ed eq 'ATTENDEE'){
			print MODULE join("\n", @{$eventdetails{$ed}}). "\n";
		    }else{
			print MODULE $eventdetails{$ed}. "\n";
		    }
		    #print STDERR "\n$ed\n:$eventdetails{$ed}\n$ed\n";
		}
		print MODULETEXT join("\t", $date, $F[6]."-".$F[7], $F[5],$F[11])."\n";
		#print VEVENT
		print MODULE "END:VEVENT\n";
	    }
	    
	    #close VCALENDAR
	    print MODULE "END:VCALENDAR\n";
	    print MODULETEXT "\n";
	}
	close MODULETEXT;
    }

}
if ($bymodule){
    foreach my $m (keys %eventsbymodule){
	open (MODULE, ">$outdir/$m.ics") or die " could not create output file $outdir/$m.ics: $!\n";
	

		    # print VCALENDAR header
	    print MODULE "BEGIN:VCALENDAR\nPRODID:David's useful timetabler v1\nVERSION:2.0\nMETHOD:REQUEST\n";

	    foreach my $e (@{$eventsbymodule{$m}}){
		print MODULE "BEGIN:VEVENT\n";
		my %eventdetails=(
		    #DTSTAMP=>"DTSTAMP:$dtstamp",
		    DTSTART=>'',ORGANIZER=>'',SUMMARY=>'',UID=>'',CATEGORIES=>'',CONTACT=>'',DTEND=>'',LOCATION=>'',DESCRIPTION=>''
		    );
		$e=~s/[\n\r]//g;
		my @F=split /\t/, $e;
		
		my $orgname="Life Sciences School Office";
		my $org='schooloffice-ls@dundee.ac.uk';
		if (exists($modulemanagers{$F[1]})){
		    $orgname=$modulemanagers{$F[1]};
		    $org=$staffnames{$orgname};
		}
		print STDERR "$F[1] $orgname : $org\n";
		#print STDERR "$orgname $org\n";
		my $mm=join(" ", reverse(split(/ /, $orgname)));
		$eventdetails{ORGANIZER}="ORGANIZER;CN=\"Module Manager: $mm\":mailto:$org";
		my $level=substr($F[1],2,1);
		$eventdetails{CONTACT}="CONTACT;CN=\"Life Sciences School Office\":mailto:lsuglevel${level}\@dundee.ac.uk";
		$eventdetails{CATEGORIES}="CATEGORIES:$F[5]";
		my $date=$F[13];
		my ($D,$m,$Y)=split / /, $date;
		print STDERR "Date: $date\n";
		print STDERR "$e\n";
		my $M=$months{$m};

		my ($starth, $startm)=split /:/,$F[6];
		$starth=$starth-isBST($date);
		my ($endh, $endm)=split /:/,$F[7];
		$endh=$endh-isBST($date);
		my $dtstart=sprintf("%4d%02d%02dT%02d%02d00Z",$Y,$M,$D,$starth,$startm);
		my $dtend=sprintf("%4d%02d%02dT%02d%02d00Z",$Y,$M,$D,$endh,$endm);
		$eventdetails{DTSTART}="DTSTART:$dtstart";
		$eventdetails{DTEND}="DTEND:$dtend";
		$eventdetails{UID}="UID:$F[1]-$Y-$F[14]\@dundee.ac.uk";
		$eventdetails{LOCATION}="LOCATION:$F[11]";
		$eventdetails{SUMMARY}="SUMMARY:$F[1] $F[3]";
		$eventdetails{DESCRIPTION}="DESCRIPTION: Staff - $F[10]";


		foreach my $ed (keys %eventdetails){
		    print MODULE join("\n", $eventdetails{$ed}), "\n";
		    #print STDERR "\n$ed\n:$eventdetails{$ed}\n$ed\n";
		}
		#print VEVENT
		print MODULE "END:VEVENT\n";
	    }
	    
	    #close VCALENDAR
	    print MODULE "END:VCALENDAR\n";
	}
    
}




sub isBST {
    my ($date)=@_;
    my ($d, $m, $y)=split / /, $date;
    my $ted=DateTime->new(year=>$y, month=>$months{$m}, day=>$d);
    
    if ($months{$m} <3 || $months{$m}>10) {
	return 0;
    } elsif ($months{$m} >3 && $months{$m} <10) {
	return 1;
    } elsif ($months{$m}==3 && $d-$ted->day_of_week() >24 ){
	return 1;
    } elsif ($months{$m}==10 && $d-$ted->day_of_week()<25){
	return 1;
    } else {
	return 0;
    }

}
