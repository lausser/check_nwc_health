package Classes::Cisco;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->{productname} =~ /Cisco NX-OS/i) {
    bless $self, 'Classes::Cisco::NXOS';
    $self->debug('using Classes::Cisco::NXOS');
  } elsif ($self->{productname} =~ /Cisco Controller/i ||
      $self->implements_mib('AIRESPACE-SWITCHING-MIB')) {
    # die AIRESPACE-WIRELESS-MIB haben manchmal auch stinknormale Switche,
    # das hat also nichts zu sagen. SWITCHING ist entscheidend.
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

