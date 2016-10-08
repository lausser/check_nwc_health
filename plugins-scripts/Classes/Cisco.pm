package Classes::Cisco;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
  '1.3.6.1.2.1',        # mib-2
  '1.3.6.1.4.1.9',      # cisco
  '1.3.6.1.4.1.9.1',      # ciscoProducts
  '1.3.6.1.4.1.9.2',      # local
  '1.3.6.1.4.1.9.3',      # temporary
  '1.3.6.1.4.1.9.4',      # pakmon
  '1.3.6.1.4.1.9.5',      # workgroup
  '1.3.6.1.4.1.9.6',      # otherEnterprises
  '1.3.6.1.4.1.9.7',      # ciscoAgentCapability
  '1.3.6.1.4.1.9.8',      # ciscoConfig
  '1.3.6.1.4.1.9.9',      # ciscoMgmt
  '1.3.6.1.4.1.9.10',      # ciscoExperiment
  '1.3.6.1.4.1.9.11',      # ciscoAdmin
  '1.3.6.1.4.1.9.12',      # ciscoModules
  '1.3.6.1.4.1.9.13',      # lightstream
  '1.3.6.1.4.1.9.14',      # ciscoworks
  '1.3.6.1.4.1.9.15',      # newport
  '1.3.6.1.4.1.9.16',      # ciscoPartnerProducts
  '1.3.6.1.4.1.9.17',      # ciscoPolicy
  '1.3.6.1.4.1.9.18',      # ciscoPolicyAuto
  '1.3.6.1.4.1.9.19',      # ciscoDomains
  '1.3.6.1.4.1.14179.1',   # airespace-switching-mib
  '1.3.6.1.4.1.14179.2',   # airespace-wireless-mib
);

sub init {
  my $self = shift;
  if ($self->{productname} =~ /Cisco NX-OS/i) {
    bless $self, 'Classes::Cisco::NXOS';
    $self->debug('using Classes::Cisco::NXOS');
  } elsif ($self->{productname} =~ /Cisco Controller/i) {
    bless $self, 'Classes::Cisco::WLC';
    $self->debug('using Classes::Cisco::WLC');
  } elsif ($self->{productname} =~ /Cisco.*(IronPort|AsyncOS)/i) {
    bless $self, 'Classes::Cisco::AsyncOS';
    $self->debug('using Classes::Cisco::AsyncOS');
  } elsif ($self->{productname} =~ /Cisco.*Prime Network Control System/i) {
    bless $self, 'Classes::Cisco::PrimeNCS';
    $self->debug('using Classes::Cisco::PrimeNCS');
  } elsif ($self->{productname} =~ /UCOS /i) {
    bless $self, 'Classes::Cisco::UCOS';
    $self->debug('using Classes::Cisco::UCOS');
  } elsif ($self->{productname} =~ /Cisco (PIX|Adaptive) Security Appliance/i) {
    bless $self, 'Classes::Cisco::ASA';
    $self->debug('using Classes::Cisco::ASA');
  } elsif ($self->{productname} =~ /Cisco/i) {
    bless $self, 'Classes::Cisco::IOS';
    $self->debug('using Classes::Cisco::IOS');
  } elsif ($self->{productname} =~ /Fujitsu Intelligent Blade Panel 30\/12/i) {
    bless $self, 'Classes::Cisco::IOS';
    $self->debug('using Classes::Cisco::IOS');
  } elsif ($self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0) eq '1.3.6.1.4.1.9.1.1348') {
    bless $self, 'Classes::Cisco::CCM';
    $self->debug('using Classes::Cisco::CCM');
  } elsif ($self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0) eq '1.3.6.1.4.1.9.1.746') {
    bless $self, 'Classes::Cisco::CCM';
    $self->debug('using Classes::Cisco::CCM');
  } elsif ($self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0) =~ /.1.3.6.1.4.1.9.6.1.83/) {
    bless $self, 'Classes::Cisco::SB';
    $self->debug('using Classes::Cisco::SB');
  }
  if (ref($self) ne "Classes::Cisco") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

