package Classes::Bluecoat;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
  '1.3.6.1.2.1.1', # RFC1213-MIB
  '1.3.6.1.2.1.10.33', # RS-232-MIB
  '1.3.6.1.2.1.22.1.1', # SNMP-REPEATER-MIB
  '1.3.6.1.2.1.25.1', # HOST-RESOURCES-MIB
  '1.3.6.1.2.1.30', # IANAifType-MIB
  '1.3.6.1.2.1.31', # IF-MIB
  '1.3.6.1.2.1.65', # WWW-MIB
  '1.3.6.1.3.25.17', # PROXY-MIB
  '1.3.6.1.4.1.3417', # BLUECOAT-MIB
  '1.3.6.1.4.1.3417', # BLUECOAT-MIB
  '1.3.6.1.4.1.3417', # BLUECOAT-MIB
  '1.3.6.1.4.1.3417.2.1', # SENSOR-MIB
  '1.3.6.1.4.1.3417.2.10', # BLUECOAT-AV-MIB
  '1.3.6.1.4.1.3417.2.2', # DISK-MIB
  '1.3.6.1.4.1.3417.2.3', # ATTACK-MIB
  '1.3.6.1.4.1.3417.2.4', # USAGE-MIB
  '1.3.6.1.4.1.3417.2.5', # WCCP-MIB
  '1.3.6.1.4.1.3417.2.6', # POLICY-MIB
  '1.3.6.1.4.1.3417.2.8', # SYSTEM-RESOURCES-MIB
  '1.3.6.1.4.1.3417.2.9', # BLUECOAT-HOST-RESOURCES-MIB
  '1.3.6.1.4.1.99.12.33', # SR-COMMUNITY-MIB
  '1.3.6.1.4.1.99.12.35', # USM-TARGET-TAG-MIB
  '1.3.6.1.4.1.99.12.36', # TGT-ADDRESS-MASK-MIB
  '1.3.6.1.4.1.99.42', # MLM-MIB
  '1.3.6.1.6.3.1', # SNMPv2-MIB
  '1.3.6.1.6.3.10', # SNMP-FRAMEWORK-MIB
  '1.3.6.1.6.3.11', # SNMP-MPD-MIB
  '1.3.6.1.6.3.1133', # COMMUNITY-MIB
  '1.3.6.1.6.3.1134', # V2ADMIN-MIB
  '1.3.6.1.6.3.1135', # USEC-MIB
  '1.3.6.1.6.3.12', # SNMP-TARGET-MIB
  '1.3.6.1.6.3.13', # SNMP-NOTIFICATION-MIB
  '1.3.6.1.6.3.14', # SNMP-PROXY-MIB
  '1.3.6.1.6.3.15', # SNMP-USER-BASED-SM-MIB
  '1.3.6.1.6.3.16', # SNMP-VIEW-BASED-ACM-MIB
  '1.3.6.1.6.3.18', # SNMP-COMMUNITY-MIB
);

sub init {
  my $self = shift;
  if ($self->{productname} =~ /Blue.*Coat.*SG\d+/i) {
    # product ProxySG  Blue Coat SG600
    # iso.3.6.1.4.1.3417.2.11.1.3.0 = STRING: "Version: SGOS 5.5.8.1, Release id: 78642 Proxy Edition"
    bless $self, 'Classes::SGOS';
    $self->debug('using Classes::SGOS');
  } elsif ($self->{productname} =~ /Blue.*Coat.*AV\d+/i) {
    # product Blue Coat AV510 Series, ProxyAV Version: 3.5.1.1, Release id: 111017
    bless $self, 'Classes::AVOS';
    $self->debug('using Classes::AVOS');
  }
  if (ref($self) ne "Classes::Bluecoat") {
    $self->init();
  }
}

