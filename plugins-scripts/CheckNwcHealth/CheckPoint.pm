package CheckNwcHealth::CheckPoint;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.2620', # CHECKPOINT-MIB
);

sub init {
  my ($self) = @_;
  if (defined $self->get_snmp_object('CHECKPOINT-MIB', 'vsxVsInstalled') &&
    $self->get_snmp_object('CHECKPOINT-MIB', 'vsxVsInstalled') != 0) {
    bless $self, 'CheckNwcHealth::CheckPoint::VSX';
    $self->debug('using CheckNwcHealth::CheckPoint::VSX');
  #} elsif ($self->get_snmp_object('CHECKPOINT-MIB', 'fwProduct') || $self->{productname} =~ /(FireWall\-1\s)|(cpx86_64)|(Linux.*\dcp )/i) {
  } elsif ($self->get_snmp_object('CHECKPOINT-MIB', 'fwProduct')) {
    bless $self, 'CheckNwcHealth::CheckPoint::Firewall1';
    $self->debug('using CheckNwcHealth::CheckPoint::Firewall1');
  } elsif ($self->get_snmp_object('CHECKPOINT-MIB', 'mgProdName')) {
    bless $self, 'CheckNwcHealth::CheckPoint::Firewall1';
    $self->debug('using CheckNwcHealth::CheckPoint::Firewall1');
  } elsif ($self->get_snmp_object('CHECKPOINT-MIB', 'osName') && $self->get_snmp_object('CHECKPOINT-MIB', 'osName') =~ /gaia/i) {
    bless $self, 'CheckNwcHealth::CheckPoint::Gaia';
    $self->debug('using CheckNwcHealth::CheckPoint::Gaia');
  } else {
    $self->no_such_model();
  }
  if (ref($self) ne "CheckNwcHealth::CheckPoint") {
    $self->init();
  }
}

