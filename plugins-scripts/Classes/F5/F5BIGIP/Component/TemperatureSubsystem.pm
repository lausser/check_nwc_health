package Classes::F5::F5BIGIP::Component::TemperatureSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['temperatures', 'sysChassisTempTable', 'Classes::F5::F5BIGIP::Component::TemperatureSubsystem::Temperature'],
  ]);
}

package Classes::F5::F5BIGIP::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{sysChassisTempIndex});
  $self->add_info(sprintf 'chassis temperature %d is %sC',
      $self->{sysChassisTempIndex},
      $self->{sysChassisTempTemperature});
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{sysChassisTempIndex}),
      value => $self->{sysChassisTempTemperature},
      warning => undef,
      critical => undef,
  );
}

