#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use MIME::Lite;

my $stafflist='';
my $templatefile='';
my $subject='Timetables';
my $ttdir='.';
my $sender='';
my $mailhost='smtp.dundee.ac.uk';
my $instruct='.'; # directory containing the ICSimport file
my $template=<<TEMPLATE;
Dear NAME,

Please find attached your timetable in iCalendar format. You can import this into most calendar programs. 

In Outlook, select the calendar, then select the File tab, Open, then Open Calendar. Select ics (iCalendar) format and open the attachment. This should then populate your calendar with the appropriate entries. Each entry lists the module organiser should you have any questions about the event.

TEMPLATE



GetOptions(
    "staff=s"=>\$stafflist,
    "template=s"=>\$templatefile,
    "timetabledir=s"=>\$ttdir,
    "subject=s"=>\$subject,
    "sender=s"=>\$sender,
    "instruct=s"=>\$instruct,
    "mailhost=s"=>\$mailhost

    );

unless ($stafflist && -e $stafflist) {
    die "No staff list specified - no emails sent\n";
}
if ($templatefile) {
    $template='';
    open (TEMPLATE, $templatefile) or (warn "Could not read template file $templatefile - using default");
    while (<TEMPLATE>) {
	$template .=$_;
    }
    close TEMPLATE;
}

my %staff=();
open (STAFF, $stafflist) or die "could not open staff list $stafflist: $!\n";

while (<STAFF>) {
    s/[\r\n]//g;
    my ($name, $email)=split(/\t/, $_);
    $staff{$name}=$email;
}
close STAFF;
MIME::Lite->send('smtp', $mailhost, Timeout => 60);

foreach my $s (keys %staff){
    print STDERR "preparing message for $s ($staff{$s})\n";
    my ($ln, $fn)=split / /, $s;
    if (-e "$ttdir/${ln}_$fn.ics" && -e "$ttdir/${ln}_$fn.txt"){
	my $tm=$template;
	my $calendar="";
	if (open (CALTXT, "$ttdir/${ln}_$fn.txt")){
	    while (my $cl = <CALTXT>){
		$calendar.=$cl;
	    }
	}
	$tm=~s/NAME/$fn $ln/g;
	$tm=~s/CALENDAR/$calendar/;
	my $msg=MIME::Lite->new(
	    From => $sender,
	    To => $staff{$s},
	    Subject => $subject,
	    Type => 'multipart/mixed'
	    ) or die "Error creating multipart message: $!\n";
	$msg->attach(
	    Type => 'TEXT',
	    Data => $tm
	    ) or die "Error adding text body: $!\n";
	$msg->attach(
	    Type=>'text/calendar',
	    Path=>"$ttdir/${ln}_$fn.ics",
	    Filename=>"${ln}_$fn.ics",
	    Disposition => 'attachment'
	    ) or die "Error adding ICS file: $!\n";
	$msg->attach(
	    Type=>'application/pdf',
	    Path=>"$instruct/ICSimport.pdf",
	    Filename=>"ICSimport.pdf",
	    Disposition => 'attachment'
	    ) or die "Error adding PDF file: $!\n";
	eval {$msg->send;};
	if ($@) {
	    warn "error sending message: $@\n";
	}else{
	    print "Successfully mailed timetable for $fn $ln\n";
	}
    } else {
	warn ("No timetable for $fn $ln.\n");
    }
}
