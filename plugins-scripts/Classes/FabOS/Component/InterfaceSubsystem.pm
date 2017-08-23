package Classes::FabOS::Component::InterfaceSubsystem;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('SW-MIB', [
    ['fcinterfaces', 'swFCPortTable', 'Monitoring::GLPlugin::SNMP::TableItem', undef, ['swFCPortIndex', 'swFCPortName']],
  ]);
  $self->SUPER::init();
}
