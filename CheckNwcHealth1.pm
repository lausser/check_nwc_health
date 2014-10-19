package MyPaloalto;
our @ISA = qw(GLPlugin::SNMP);

sub init {
  my $self = shift;
  use Data::Dumper;
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'GLPlugin::TableItem'],
  ]);

  printf "%s\n", Data::Dumper::Dumper($self);
}


