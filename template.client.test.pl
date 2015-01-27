#!/usr/bin/perl -w
#
# based on bb-mysql - mysql check and metrics
# cgoyard:2006-07-18
# Edit "$auth" variable to personalize autentication.
use strict;
use v5.10.0;
use warnings;
use Data::Dumper;
use Xymon;
use Xymon::Graph;

use constant DEBUG      => 1;
use constant true       => 1;
use constant false      => '';

my %config = &loadenv ();


my $TESTNAME    = "TEST";


######################################################################
# here we go
############
    my $xymon = new Xymon ("Disc info");
    $xymon->green();
    $xymon->say ("HELLO WORLD");
    $xymon->print("ALL IS ". Dumper (\%config));
    $xymon->print("OK.");
    $xymon->send;
        my $object = new Xymon::Graph($TESTNAME);
        $object->insert("ds0" , '4');
        $object->insert("ds1" , '12');
        $object->send;

exit 0;


sub dolog {
    my ($msg) = @_;
    my ($sec,$min,$hour,$day,$mon,$year) = localtime;
    my $time;
    $time = sprintf '[%-2.2d-%-2.2d-%-2.2d@%-2.2d:%-2.2d:%-2.2d]', $year-100, $mon+1,
      $day, $hour, $min, $sec,
    print "$time $msg\n" if DEBUG;

    return 1;
}

# Log and die
sub logfatal {
    my ($msg) = @_;

    do_log($msg);
    &quit;
}

