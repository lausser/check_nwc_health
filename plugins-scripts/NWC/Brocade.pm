package NWC::Brocade;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

sub init {
  my $self = shift;
  my $swFirmwareVersion = $self->get_snmp_object('SW-MIB', 'swFirmwareVersion');
  if (! $swFirmwareVersion) {
    #  $self->add_rawdata('1.3.6.1.2.1.1.1.0', 'Cisco');
  }
  foreach ($self->get_snmp_table_objects(
      'ENTITY-MIB', 'entPhysicalTable')) {
    if ($_->{entPhysicalDescr} =~ /Brocade/) {
      $self->{productname} = $_->{FabOS};
    }
  }
  if ($self->{productname} =~ /FabOS/i) {
    bless $self, 'NWC::FabOS';
    $self->debug('using NWC::FabOS');
  }
  $self->init();
}

