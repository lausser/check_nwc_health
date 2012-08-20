package NWC::F5;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

use constant trees => (
    '1.3.6.1.4.1.3375.1.2.1.1.1', # F5-3DNS-MIB
    '1.3.6.1.4.1.3375', # F5-BIGIP-COMMON-MIB
    '1.3.6.1.4.1.3375.2.2', # F5-BIGIP-LOCAL-MIB
    '1.3.6.1.4.1.3375.2.1', # F5-BIGIP-SYSTEM-MIB
    '1.3.6.1.4.1.3375.1.1.1.1', # LOAD-BAL-SYSTEM-MIB
    '1.3.6.1.4.1.2021', # UCD-SNMP-MIB
);

sub init {
  my $self = shift;
  if ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i) {
    bless $self, 'NWC::F5::F5BIGIP';
    $self->debug('using NWC::F5::F5BIGIP');
  }
  $self->init();
}

