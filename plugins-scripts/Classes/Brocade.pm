package Classes::Brocade;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode !~ /device::uptime/) {
    foreach ($self->get_snmp_table_objects(
        'ENTITY-MIB', 'entPhysicalTable', undef, ['entPhysicalDescr'])) {
      if ($_->{entPhysicalDescr} =~ /Brocade/) {
        $self->{productname} = "FabOS";
      }
    }
    my $swFirmwareVersion = $self->get_snmp_object('SW-MIB', 'swFirmwareVersion');
    if ($swFirmwareVersion && $swFirmwareVersion =~ /^v6/) {
      $self->{productname} = "FabOS"
    }
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
  } elsif ($self->{productname} =~ /ICX6|FastIron/i) {
    bless $self, 'Classes::Foundry';
    $self->debug('using Classes::Foundry');
  } elsif ($self->implements_mib('SW-MIB')) {
    bless $self, 'Classes::FabOS';
    $self->debug('using Classes::FabOS');
  }
  if (ref($self) ne "Classes::Brocade") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

