package NWC::Brocade;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

sub init {
  my $self = shift;
  foreach ($self->get_snmp_table_objects(
      'ENTITY-MIB', 'entPhysicalTable')) {
    if ($_->{entPhysicalDescr} =~ /Brocade/) {
      $self->{productname} = $_->{entPhysicalDescr};
    }
  }
  if ($self->{productname} =~ /Brocade300/i) {
    bless $self, 'NWC::Brocade300';
    $self->debug('using NWC::Brocade300');
  }
  $self->init();
}

