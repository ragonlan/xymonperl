# Perl module to send reports rrd data to the Xymon system monitor
# (formerly known as Hobbit)
#
# Copyright (C) 2008, 2009 Christoph Berg <myon@debian.org>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

package Xymon::Graph;

use Data::Dumper;
use strict;
use warnings;
#use v5.10;

use vars qw($VERSION);
$VERSION=0.2;

sub new ($)
{
    my $class = shift;
    my $arg = shift;
    my ($BB, $BBDISP);

    unless (ref $arg) {
        $arg = {
              test => $arg,
        };
    }

    unless ($arg->{test}) {
         print STDERR "$0: test name undefined\n";
         exit 1;
    }

    $ENV{CLIENTHOSTNAME} = &expand_string ($ENV{CLIENTHOSTNAME}) if $ENV{CLIENTHOSTNAME};

    my $self = {
        _machine  => ($arg->{hostname} || $ENV{CLIENTHOSTNAME} ||
                      $ENV{MACHINEDOTS} || $ENV{MACHINE} || "unknown"),
        _testname  => $arg->{test} || $arg->{testname},
        _rrdname   => $arg->{rrdname} || undef,
        _datatype  => $arg->{datatype} || "GAUGE",
        _min       => $arg->{min} || '0',
        _max       => $arg->{max} || 'U',
        _heartbeat => $arg->{heartbeat} || '600',
        _cmdline   => "data ",
        _data      => {}
    };

    $self->{_testname} =~ s/\//_/ if $self->{_testname};  # '/' character is not permited as rrd name.
    $self->{_rrdname}  =~ s/\//_/ if $self->{_rrdname} ;

    bless $self, $class;
    return $self;
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

sub insert
{
        my ( $self, $dataname , $dataval, $datatype ) = @_;
        my $rrdname = $self->{_rrdname} || $self->{_testname};
        
        $datatype =  $datatype || $self->{_datatype};
        push (@{$self->{_data}->{$rrdname}} , [$dataname, $dataval, $datatype]);
        #Ssay Dumper $self->{_data} ;
        return $self;
}

sub print
{
  my ( $self ) = @_;
    if (defined $self->{_rrdname}) {
        print  $self->{ _cmdline} ." ". $self->{ _machine} .".trends\n[". $self->{_testname}.",".$self->{_rrdname}.".rrd]\n";
    }else{
        print  $self->{ _cmdline} ." ". $self->{ _machine} .".trends\n[". $self->{_testname}.".rrd]\n";
    }

  for my $foo (keys %{$self->{_data}})
  {
       for my $i (0 .. $#{$self->{ _data}->{$foo}} )
       {
       print "DS:".  $self->{ _data}->{$foo}[$i][0]  .":". $self->{ _data}->{$foo}[$i][2] . ":600:0:U \t" . $self->{ _data}->{$foo}[$i][1];
       }
  }
  print '"';
  return $self;
}

sub send
{
    my ( $self ) = @_;
    my $output;
    my $min = $self->{_min};
    my $max = $self->{_max};

    if (defined $self->{_rrdname}) {
        $output =  $self->{ _cmdline} ." ". $self->{ _machine} .".trends\n[". $self->{_testname}.",".$self->{_rrdname}.".rrd]\n";
    }else{
        $output =  $self->{ _cmdline} ." ". $self->{ _machine} .".trends\n[". $self->{_testname}.".rrd]\n";
    }

    for my $foo (keys %{$self->{_data}})
    {
        for my $i (0 .. $#{$self->{ _data}->{$foo}} )
        {
            $output .= "DS:". $self->{ _data}->{$foo}[$i][0] .
                       ":". $self->{ _data}->{$foo}[$i][2] .
                       ":". $self->{_heartbeat} .
                       ":$min:$max " . $self->{ _data}->{$foo}[$i][1] .
                       "\n";
        }
    }
    #$output .= '"';
#    system($ENV{BB}." ".$ENV{BBDISP}." ".$output);
    if ($ENV{BB} and $ENV{BBDISP}) {
       open F, "| $ENV{BB} $ENV{BBDISP} @" or die "error\n";
#      say $ENV{BB}." ".$ENV{BBDISP}."\n";
#	   say localtime()."$ENV{BB} $ENV{BBDISP} ".$output;
       print F $output;
       close F;
    } else {
        print $output;
    }

    return $self;
}


1;
