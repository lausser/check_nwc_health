package Classes::Brocade;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
  '1.3.6.1.2.1',        # mib-2
  '1.3.6.1.4.1.289',    # mcData
  '1.3.6.1.4.1.333',    # cnt
  '1.3.6.1.4.1.1588',   # bcsi
  '1.3.6.1.4.1.1991',   # foundry
  '1.3.6.1.4.1.4369',   # nishan
);

sub init {
  my $self = shift;
  foreach ($self->get_snmp_table_objects(
      'ENTITY-MIB', 'entPhysicalTable')) {
    if ($_->{entPhysicalDescr} =~ /Brocade/) {
      $self->{productname} = "FabOS";
    }
  }
  my $swFirmwareVersion = $self->get_snmp_object('SW-MIB', 'swFirmwareVersion');
  if ($swFirmwareVersion && $swFirmwareVersion =~ /^v6/) {
    $self->{productname} = "FabOS"
  }
  if ($self->{productname} =~ /EMC\s*DS.*4700M/i) {
    bless $self, 'Classes::MEOS';
    $self->debug('using Classes::MEOS');
  } elsif ($self->{productname} =~ /EMC\s*DS-24M2/i) {
    bless $self, 'Classes::MEOS';
    $self->debug('using Classes::MEOS');
  } elsif ($self->{productname} =~ /FabOS/i) {
    bless $self, 'Classes::FabOS';
    $self->debug('using Classes::FabOS');
  } elsif ($self->{productname} =~ /ICX6/i) {
    bless $self, 'Classes::Foundry';
    $self->debug('using Classes::Foundry');
  }
  if (ref($self) ne "Classes::Brocade") {
    $self->init();
  }

}

