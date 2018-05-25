package Classes::F5;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.3375.1.2.1.1.1', # F5-3DNS-MIB
    '1.3.6.1.4.1.3375', # F5-BIGIP-COMMON-MIB
    '1.3.6.1.4.1.3375.2.2', # F5-BIGIP-LOCAL-MIB
    '1.3.6.1.4.1.3375.2.1', # F5-BIGIP-SYSTEM-MIB
    '1.3.6.1.4.1.3375.1.1.1.1', # LOAD-BAL-SYSTEM-MIB
    '1.3.6.1.4.1.2021', # UCD-SNMP-MIB
);

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i ||
      $self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.3375\./) {
    bless $self, 'Classes::F5::F5BIGIP';
    $self->debug('using Classes::F5::F5BIGIP');
  }
  if (ref($self) ne "Classes::F5") {
    $self->init();
  }
}

