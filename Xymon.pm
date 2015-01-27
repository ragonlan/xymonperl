package Xymon;

use strict;
use warnings;
use Config::General;
use Data::Dumper;
use Cwd 'abs_path';

#use vars qw($VERSION);

my $XYMONCFG;
$XYMONCFG = "/usr/lib/xymon/client/etc/xymonclient.cfg" if (-f "/usr/lib/xymon/client/etc/xymonclient.cfg");
$XYMONCFG = "/usr/lib/hobbit/client/etc/hobbitclient.cfg" if (-f "/usr/lib/hobbit/client/etc/hobbitclient.cfg");
$XYMONCFG = "/etc/xymon/xymonserver.cfg" if (-f "/etc/xymon/xymonserver.cfg");


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = 0.5;
    @EXPORT  = qw( loadenv );
    @ISA     = qw( Exporter );
}

my %color = (
        blue  => 0,
        clear => 0,
        green => 1,
        purple => 2,
        yellow => 3,
        red => 4,
);

my $gself = {
        hostname => 'xymon.pm',
        test => 'uninitialized',
};
bless $gself;

sub max_color ($$)
{
        my ($a, $b) = @_;
        die "color $a unknown" unless exists $color{$a};
        die "color $b unknown" unless exists $color{$b};
        return $color{$b} > $color{$a} ? $b : $a;
}

sub new ($)
{
        my $class = shift;
        my $arg = shift;
        unless (ref $arg) {
                $arg = {
                        test => $arg,
                };
        }
        unless ($arg->{test}) {
                print STDERR "$0: test name undefined\n";
                exit 1;
        }
	if ($ENV{'CLIENTHOSTNAME'}){
		my $aux = $ENV{'CLIENTHOSTNAME'};
        	while ($ENV{'CLIENTHOSTNAME'} =~ /`(.+)`/g){
	          my $output = `$1`;
        	  chomp $output;
	          $aux =~ s/`$1`/$output/;
        	}
	        $ENV{'CLIENTHOSTNAME'} = $aux;
	}

   $ENV{CLIENTHOSTNAME} = &expand_string ($ENV{CLIENTHOSTNAME}) if $ENV{CLIENTHOSTNAME};
        my $self = {
                type => ($arg->{type} || 'status'),
                color => $arg->{color} || 'clear',
                text => $arg->{text} || '',
                hostname => ($arg->{hostname} || $ENV{CLIENTHOSTNAME} || $ENV{MACHINEDOTS} || $ENV{MACHINE} || "unknown"),
                test => $arg->{test},
                title => $arg->{title},
                lifetime=> $arg->{lifetime},
        };
        $gself = $self;
        bless $self;
}

sub expand_string {
  # this is for "CLIENTHOSTNAME=`hostname`.basekit"
  # Be carefull because we are executing thing in shell.
  my $var = shift;
  my $aux = $var;
  while ($var =~ /`(.+)`/g){
        my $output = `$1`;
        chomp $output;
        $aux =~ s/`$1`/$output/;
  }
  return $aux;
}

sub loadconf ($)
{
    my $self = shift;
    $XYMONCFG = shift if $_[0];
 # Parse general config file
    my $conf = new Config::General(
                        -ConfigFile       => $XYMONCFG,
                        -UseApacheInclude => 1,
                        -IncludeRelative  => 0,
                        -InterPolateEnv   => 1 );
    my %config = $conf->getall;
    $config{'XYMWEBBACKGROUND'}='blue';
    $config{'XYMONDREL'}="$0 v$VERSION";
    $config{'XYMWEBDATE'}=localtime;

  # Parse cliente config file if any.
    my $DEF_CONF;
    $DEF_CONF = '/etc/default/hobbit-client'  if -f '/etc/default/hobbit-client';
    $DEF_CONF = '/etc/default/xymon-client'   if -f '/etc/default/xymon-client';
    $DEF_CONF = '/etc/sysconfig/xymon-client' if -f '/etc/sysconfig/xymon-client';

    my  ($dconf, %dconfig);
    if ($DEF_CONF){
      $dconf =  new Config::General(
                        -ConfigFile       => $DEF_CONF,
                        -UseApacheInclude => 1,
                        -IncludeRelative  => 0,
                        -InterPolateEnv   => 1 );

      %dconfig = $dconf->getall;

      # this is for "CLIENTHOSTNAME=`hostname`.basekit"
      $config{CLIENTHOSTNAME} = &expand_string ($config{CLIENTHOSTNAME}) if $config{CLIENTHOSTNAME};
    }
    $config{'CLIENTHOSTNAME'} = $dconfig{'CLIENTHOSTNAME'} if not $config{'CLIENTHOSTNAME'} and $dconfig{'CLIENTHOSTNAME'};
    $config{'CLIENTHOSTNAME'} = $config{'MACHINEDOTS'}     if not $config{'CLIENTHOSTNAME'} and $config{'MACHINEDOTS'} ;
    $config{'CLIENTHOSTNAME'} = `/bin/uname -n`            if not $config{'CLIENTHOSTNAME'};

    # Initialize hostname to CLIENTHOSTNAME if hostname is unknown.
    $self->{hostname} = $config{'CLIENTHOSTNAME'} if $self->{hostname} eq 'unknown';

    # If there is no XYMONCLIENTHOME we have to declare some environments
    if (not $config{'XYMONCLIENTHOME'}){
        my $path = abs_path ($0);
        my ($bpath) = ($path =~ /(.+)\/ext\/.+/);
        $config{'XYMONCLIENTHOME'} = $bpath;
        $config{'XYMONHOME'}  = $bpath;
        $config{'XYMONTMP'}   = $bpath . '/tmp';
        $config{'XYMONLOG'}   = $bpath . '/log';
        $config{'XYMON'}      = $bpath . '/bin/xymon' if -f $bpath.'/bin/xymon';
        $config{'HOBBIT'}     = $bpath . '/bin/xymon' if -f $bpath.'/bin/bb';
        $config{'BBHOME'}     = $bpath;
        $config{'HOBBITHOME'} = $bpath;
    }

    return %config;
}



sub add_color ($)
{
        my ($self, $color) = @_;
        $self->{color} = max_color ($self->{color}, $color);
}

sub print ($)
{
        my ($self, $text) = @_;
        $self->{text} .= $text;
}

sub say ($)
{
    my ($self, $text) = @_;
    $self->{text} .= "$text\n";
}

sub color_print ($$)
{
        my ($self, $color, $text) = @_;
        $self->add_color ($color);
        $self->print ($text);
}

sub getcolor ($)
{
    my ($self, $color, $text) = @_;
    return $self->{color};
}

sub color_line ($$)
{
        my ($self, $color, $text) = @_;
        $self->color_print ($color, "&$color $text");
}


sub clear ($)
{
        my ($self, $text) = @_;
        $self->add_color ('clear') unless $text;
        $self->color_print ('clear', "&clear $text") if $text;
}


sub green ($)
{
        my ($self, $text) = @_;
        $self->add_color ('green') unless $text;
        $self->color_print ('green', "&green $text") if $text;
        return $self->getcolor;
}

sub yellow ($)
{
        my ($self, $text) = @_;
        $self->add_color ('yellow') unless $text;
        $self->color_print ('yellow', "&yellow $text") if $text;
        return $self->getcolor;

}

sub red ($)
{
        my ($self, $text) = @_;
        $self->add_color ('red') unless $text;
        $self->color_print ('red', "&red $text") if $text;
        return $self->getcolor;
}


sub send ()
{
        my $self = shift;
        my $report = "$self->{type} $self->{hostname}.$self->{test}";
        $report = "$self->{type}+$self->{lifetime} $self->{hostname}.$self->{test}" if $self->{lifetime};
        if ($self->{type} eq 'status') {
                my $date = scalar localtime;
                my $title = '';
                if ($self->{color} eq 'green') {
                        $title = "$self->{test} OK";
                } elsif ($self->{color} eq 'yellow' or $self->{color} eq 'red') {
                        $title = "$self->{test} NOT ok";
                }
                $title = ' - ' . ($self->{title} ? $self->{title} : $title)
                        if ($self->{title} or $title);
                $report .= " $self->{color} $date$title";
        }
        $report .= "\n$self->{text}";
        $report .= "\n" unless ($report =~ /\n\n$/);
        if ($ENV{BB} and $ENV{BBDISP}) {
                open F, "| $ENV{BB} $ENV{BBDISP} @";
                print F $report;
                close F;
        } else {
                print $report;
        }
}

sub moan ($)
{
        my ($self, $msg) = @_;
        my $date = scalar localtime;
        print STDERR "$date $0 $gself->{hostname}.$gself->{test}: $msg";
        $gself->color_line ('yellow', "Warning: $msg\n");
}

sub croak ($)
{
        my ($self, $msg) = @_;
        my $date = scalar localtime;
        print STDERR "$date $0 $gself->{hostname}.$gself->{test}: $msg";
        $gself->color_line ('red', "Error: $msg\n" );
        $gself->send();
        exit 1;
}

sub Fmoan ($)
{
        my $msg = shift;
        my $date = scalar localtime;
        print STDERR "$date $0 $gself->{hostname}.$gself->{test}: $msg";
        $gself->color_line ('yellow', "Warning: $msg\n");
}

sub Fcroak ($)
{
        my $msg = shift;
        my $date = scalar localtime;
        print STDERR "$date $0 $gself->{hostname}.$gself->{test}: $msg";
        $gself->color_line ('red', "Error: $msg\n" );
        $gself->send();
        exit 1;
}



$SIG{__WARN__} = \&Fmoan;
$SIG{__DIE__} = \&Fcroak ;


sub loadenv
{
    $XYMONCFG = $_[0] if $_[0];
    my $DEF_CONF;
    $DEF_CONF = '/etc/default/hobbit-client'  if -f '/etc/default/hobbit-client';
    $DEF_CONF = '/etc/default/xymon-client'   if -f '/etc/default/xymon-client';
    $DEF_CONF = '/etc/sysconfig/xymon-client' if -f '/etc/sysconfig/xymon-client';

    my $conf = new Config::General(
                        -ConfigFile       => $XYMONCFG,
                        -UseApacheInclude => 1,
                        -IncludeRelative  => 0,
                        -InterPolateEnv   => 1 );
    my %config = $conf->getall;
    $config{'XYMWEBBACKGROUND'}='blue';
    $config{'XYMONDREL'}="$0 v$VERSION";
    $config{'XYMWEBDATE'}=localtime;

    my  ($dconf, %dconfig);
    if ($DEF_CONF){
      $dconf =  new Config::General(
                        -ConfigFile       => $DEF_CONF,
                        -UseApacheInclude => 1,
                        -IncludeRelative  => 0,
                        -InterPolateEnv   => 1 );

      %dconfig = $dconf->getall;

      # this is for "CLIENTHOSTNAME=`hostname`.basekit"
      my $aux = $config{'CLIENTHOSTNAME'};
      while ($config{'CLIENTHOSTNAME'} =~ /`(.+)`/g){
          my $output = `$1`;
          chomp $output;
          $aux =~ s/`$1`/$output/;
      }
      $config{'CLIENTHOSTNAME'} = $aux;
    }
    $config{'CLIENTHOSTNAME'} = $dconfig{'CLIENTHOSTNAME'} if not $config{'CLIENTHOSTNAME'} and $dconfig{'CLIENTHOSTNAME'};
    $config{'CLIENTHOSTNAME'} = $config{'MACHINEDOTS'}     if not $config{'CLIENTHOSTNAME'} and $config{'MACHINEDOTS'} ;
    $config{'CLIENTHOSTNAME'} = `/bin/uname -n`            if not $config{'CLIENTHOSTNAME'};

    if (not $config{'XYMONCLIENTHOME'}){
        my $path = abs_path($0);
        my ($bpath) = ($path =~ /(.+)\/ext\/.+/);
        $config{'XYMONCLIENTHOME'} = $bpath;
        $config{'XYMONHOME'}  = $bpath;
        $config{'XYMONTMP'}   = $bpath . '/tmp';
        $config{'XYMONLOG'}   = $bpath . '/log';
        $config{'XYMON'}      = $bpath . '/bin/xymon' if -f $bpath.'/bin/xymon';
        $config{'HOBBIT'}     = $bpath . '/bin/xymon' if -f $bpath.'/bin/bb';
        $config{'BBHOME'}     = $bpath;
        $config{'HOBBITHOME'} = $bpath;

    }

    return %config;
}

1;


=head1 NAME

Xymon  - OO interface to send xymon status.

=head1 SYNOPSYS

    use Xymon;

=head1 DESCRIPTION

    This is a modification of Hobbit.pm (by  Christoph Berg <myon@debian.org>)
    from Debian proyect. It is adapted to use xymon instead Hobbit and some methods was added.

=head1 USAGE

    use Xymon;

    my $xymon = new Xymon ('testname');

    my %conf = $xymon->loadconf;

    $xymon->green;
    $xymon->say ("Xymon is in ". $conf{XYMONHOME});
    $xymon->red;
    $xymon->color_line ('red', "Something critical just occurred");
    $xymon->send;

    $xymon2->new Xymon ({   hostname => 'test2', 
                            test     => 'testname2', 
                            color    => 'green',
                            title    => 'this is a title'});
    $xymon2->send;

=head1 COPYRIGHT

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following
    conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

    Raul gonzalez (ragonlan@gmail.com)

=cut
