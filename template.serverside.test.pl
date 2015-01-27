#!/usr/bin/perl -w
#
# based on bb-mysql - mysql check and metrics
# cgoyard:2006-07-18
# Edit "$auth" variable to personalize autentication.
use strict;
use Data::Dumper;
use 5.10.1;
use Xymon;
use Xymon::Graph;
use Config::General;
use Config::Tiny;

use constant DEBUG      => 1;
use constant true       => 1;
use constant false      => '';

my $TESTNAME    = "testname";  # disk operations

my $BBHOME;
my $VERSION =0.1;
my %config = &loadenv ();
my @hosts = get_hostname($TESTNAME);

### Load ini config.
my $configfile = $config{XYMONHOME}."/etc/$TESTNAME.ini" || "/etc/xymon/$TESTNAME.ini";
my $configIni = Config::Tiny->new;
$configIni = Config::Tiny->read( $configfile );
$configIni = SplitSubs ($configIni);

sub dolog;

######################################################################
# here we go
############

for my $host (@hosts) {
    my ($h,$i,$p) = @$host;
        my $xymon = new Xymon($TESTNAME);
        $xymon->add_color ('green');
        $xymon->print ($h . " > " .$i . " > " . $p);
        $xymon->send;
}

exit 0;


######################################################################
# toolbox
###########

 # Sub to log data to a logfile and print to screen if verbose
sub dolog {
    my ($msg) = @_;
    my ($sec,$min,$hour,$day,$mon,$year) = localtime;
    my $time;
    $time = sprintf '[%-2.2d-%-2.2d-%-2.2d@%-2.2d:%-2.2d:%-2.2d]', $year-100, $mon+1, $day, $hour, $min, $sec;
    print "$time $msg\n" if DEBUG;

    return 1;
}

 # Log and die
sub logfatal {
    my ($msg) = @_;

    do_log($msg);
    &quit;
  }

sub get_hostname {
        my $testname = shift;
        my (@do_hosts,$ip, $host, $param);
        my $BBHOME;
        defined $ENV{"BBHOME"} ? $BBHOME = $ENV{BBHOME} : $BBHOME = $config{BBHOME};
        $ENV{HOSTSCFG} = $config{HOSTSCFG} if not $ENV{HOSTSCFG};
        open BBFILE, "$BBHOME/bin/bbhostshow |" or die "Can't execute $BBHOME/bin/bbhostshow";
        while (<BBFILE>){
                chomp;
                if (/^(\S+)\s+(\S+)\s*#.*\b$testname(;(\S+))?/) {
                        $host  = $2;
                        $ip    = $1;
                        $param = $4 || 'public';
                        push (@do_hosts,[$host,$ip,$param]);
                        say "$host>$ip>$param";
                }else{
                        next;
                }
        }
        close BBFILE;
        return @do_hosts;
}

sub SplitSubs {
    my $ini = shift;
    my $char = shift || '.';  # FIXME. by default '.' is the character to split up subgroups, It should be personalize.
    foreach my $group ( keys %{$ini} ) {
        foreach my $vars ( keys %{$ini->{$group}} ) {
            # Mega expresion regular de nivel 20. Divide la cadena por el caracter '.' salvo que lo anteceda una '\'
          my @subvars  = split (/(?<!\\)\./, $vars);
          if ( $#subvars > 0 ){ #Has more than 1 element
            my $index = $ini->{$group};
            for ( my $i = 0; $i <= $#subvars; $i++ ) {
              $subvars[$i] =~ s/\\\./\./;
              if ( $i == $#subvars ) {   # Last element
                  $index->{$subvars[$i]} = $ini->{$group}->{$vars};
                  delete $ini->{$group}->{$vars};
              }
              else{                                  # Every other elemnt
                  $index->{$subvars[$i]} = {} if not $index->{$subvars[$i]};
                  $index = $index->{$subvars[$i]};
              }
            }
          }
        }
    }
  return $ini;
}

