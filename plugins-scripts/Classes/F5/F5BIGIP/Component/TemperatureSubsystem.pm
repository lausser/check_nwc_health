package Classes::F5::F5BIGIP::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['temperatures', 'sysChassisTempTable', 'Classes::F5::F5BIGIP::Component::TemperatureSubsystem::Temperature'],
  ]);
}

package Classes::F5::F5BIGIP::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'chassis temperature %d is %sC',
      $self->{sysChassisTempIndex},
      $self->{sysChassisTempTemperature});
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{sysChassisTempIndex}),
      value => $self->{sysChassisTempTemperature},
  );
}

