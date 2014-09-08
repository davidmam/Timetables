#!/usr/bin/perl -w

use strict;

use MIME::Lite;

my $subject="Timetables - let me know if this works for you";

my $ics='level3/Martin_David.ics';

my $txt='';
open (ICS, $ics) or die "could not open ICS fil: $!\n";
while (my $l=<ICS>) {
    $txt.=$l;
}
close ICS;
MIME::Lite->send('smtp', 'smtp.dundee.ac.uk', Timeout => 60);

my $msg=MIME::Lite->new(
    From => 'The SLST Timetabling Pixie <noreply@dundee.ac.uk>',
    To => 'd.m.a.martin@dundee.ac.uk',
    Subject => $subject,
    Type => 'text/calendar',
    Data => $txt
    ) or die "Error creating calendar message: $!\n";

$msg->send;


