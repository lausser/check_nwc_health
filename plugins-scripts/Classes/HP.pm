package Classes::HP;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.11.2.14.11.1.2', # HP-ICF-CHASSIS
    '1.3.6.1.2.1.1.7.11.12.9', # STATISTICS-MIB (old?)
    '1.3.6.1.2.1.1.7.11.12.1', # NETSWITCH-MIB (old?)
    '1.3.6.1.4.1.11.2.14.11.5.1.9', # STATISTICS-MIB
    '1.3.6.1.4.1.11.2.14.11.5.1.1', # NETSWITCH-MIB

);

sub init {
  my $self = shift;
  if ($self->{productname} =~ /Procurve/i ||
      ($self->implements_mib('HP-ICF-CHASSIS') &&
      $self->implements_mib('NETSWITCH-MIB'))) {
    bless $self, 'Classes::HP::Procurve';
    $self->debug('using Classes::HP::Procurve');
  }
  if (ref($self) ne "Classes::HP") {
    $self->init();
  }
}

