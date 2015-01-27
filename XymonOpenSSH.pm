package XymonOpenSSH;

use strict;
use warnings;
use Data::Dumper;
use Net::OpenSSH;

our @ISA = qw(Net::OpenSSH);

my $MAX_TRIES = 1;
my $DEBUG = 0;
my $output;
my %opts_c;
my $class;
sub dolog;

sub new {
    $class = shift;
    %opts_c = @_;
    my $self;

    $DEBUG = delete $opts_c{debug} if defined $opts_c{debug};

    if( defined $opts_c{retry} ) {
        $MAX_TRIES = delete $opts_c{retry};
        $MAX_TRIES++;
    }

    my $cmd;
    if( defined $opts_c{cmd} ) {
        $cmd = delete $opts_c{cmd};
    }
    $self = &connect(%opts_c);
#    my $try = 1;
#    TRY:
#    for $try (1 .. $MAX_TRIES) {
#        dolog "hola $try:";
#        dolog Dumper( \%opts_c );
#        $self = $class->SUPER::new( %opts_c );
#        if( $self->error ) {
#        } else {
#                last TRY;
#        }
#        if ( $try ==  $MAX_TRIES ) {
#                warn "Superado numero de reintentos de conexion. ". $self->error . " after $try times.";
#        }
#    }
#    dolog "Connection done;";

    bless $self, $class;
    if( $cmd && ! $self->error ) {
        dolog "Executing commnad '$cmd'.";
        $self->cmd( {
                timeout => $opts_c{timeout},
                stderr_discard => 1,
                }, $cmd );
    }

    return $self;
}


sub cmd {
    my $self = shift;
    my ($opts, $cmd) = @_;
    my @out;

    my $try = 1;
    TRY:
    for $try (1 .. $MAX_TRIES) {
        dolog "Commnad try $try: $cmd";
        @out = $self->capture($opts, $cmd);
        if( $self->error ) {
          dolog "Error, lets try again..." . $self->error ;
          $self->connect( %opts_c );
        } else {
                last TRY;
        }
        if ( $try ==  $MAX_TRIES ) {
                warn "Superado numero de reintentos de ejecucion. ".$self->error . " after $try times.";
        }
    }

    $output = \@out;
    return \@out;
}

sub output {
        return $output;
}

sub dolog {
    my ($msg) = @_;
    return 0 unless $DEBUG;
    my ($sec,$min,$hour,$day,$mon,$year) = localtime;
    my $ts = sprintf '[%-2.2d-%-2.2d-%-2.2d@%-2.2d:%-2.2d:%-2.2d]', $year-100, $mon+1, $day, $hour, $min, $sec,;
    print "$ts $msg\n";

    return 1;
}

sub connect {
  my (%opts) = @_;
  my $try = 1;
  my $self;
  TRY:
    for $try (1 .. $MAX_TRIES) {
        dolog "Connecting try $try to ".$opts{'host'}.":";
        $self = $class->SUPER::new( %opts );
        if( $self->error ) {
        } else {
                last TRY;
        }
        if ( $try ==  $MAX_TRIES ) {
                warn "Superado numero de reintentos de conexion. ". $self->error . " after $try times.";
                return 0;
        }
    }

  return $self;
}

1;
