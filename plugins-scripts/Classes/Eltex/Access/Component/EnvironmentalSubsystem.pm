package Classes::Eltex::Access::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ELTEX-MIB', [
      ['fans', 'eltexFanTable', 'Classes::Eltex::Access::Component::EnvironmentalSubsystem::Fan'],
      ['temperatures', 'eltexSensorTable', 'Classes::Eltex::Access::Component::EnvironmentalSubsystem::Temperature']
  ]);
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{fans}}, @{$self->{temperatures}}) {
    $_->check();
  }
}
package Classes::Eltex::Access::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s is %s',
    $self->{eltexFanDescription}, $self->{eltexFanStatus});
  if ($self->{eltexFanStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{eltexFanStatus} eq 'notPresent') {
    $self->add_warning();
  } elsif ($self->{eltexFanStatus} eq 'unknown') {
    $self->add(); # Actually fan is not present on device, but in index...
  }
}

package Classes::Eltex::Access::Component::EnvironmentalSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'sensor %s is %s°C',
    $self->{eltexSensorDescription}, $self->{eltexSensorStatus});
  $self->set_thresholds(warning => 55, critical => 65);
  $self->add_message($self->check_thresholds($self->{eltexSensorStatus}));
  $self->add_perfdata(
    label => 'sensor_'.$self->{eltexSensorDescription}.'_temp',
    value => $self->{eltexSensorStatus},
    uom => '°C',
  );
}
