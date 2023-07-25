package CheckNwcHealth::Brocade;
our @ISA = qw(CheckNwcHealth::Device);
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
    bless $self, 'CheckNwcHealth::MEOS';
    $self->debug('using CheckNwcHealth::MEOS');
  } elsif ($self->{productname} =~ /EMC\s*DS-24M2/i) {
    bless $self, 'CheckNwcHealth::MEOS';
    $self->debug('using CheckNwcHealth::MEOS');
  } elsif ($self->{productname} =~ /FabOS/i) {
    bless $self, 'CheckNwcHealth::FabOS';
    $self->debug('using CheckNwcHealth::FabOS');
  } elsif ($self->{productname} =~ /ICX6|FastIron/i) {
    bless $self, 'CheckNwcHealth::Foundry';
    $self->debug('using CheckNwcHealth::Foundry');
  } elsif ($self->implements_mib('SW-MIB')) {
    bless $self, 'CheckNwcHealth::FabOS';
    $self->debug('using CheckNwcHealth::FabOS');
  }
  if (ref($self) ne "CheckNwcHealth::Brocade") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

