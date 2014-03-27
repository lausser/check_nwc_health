package Classes::Cisco::IOS::Component::VoltageSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  my $index = 0;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['voltages', 'ciscoEnvMonVoltageStatusTable', 'Classes::Cisco::IOS::Component::VoltageSubsystem::Voltage'],
  ]);
  foreach (@{$self->{voltages}}) {
    $_->{ciscoEnvMonVoltageStatusIndex} ||= $index++;
  }
}

package Classes::Cisco::IOS::Component::VoltageSubsystem::Voltage;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('v', $self->{ciscoEnvMonVoltageStatusIndex});
  $self->add_info(sprintf 'voltage %d (%s) is %s',
      $self->{ciscoEnvMonVoltageStatusIndex},
      $self->{ciscoEnvMonVoltageStatusDescr},
      $self->{ciscoEnvMonVoltageState});
  if ($self->{ciscoEnvMonVoltageState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonVoltageState} ne 'normal') {
    $self->add_critical();
  }
  $self->add_perfdata(
      label => sprintf('mvolt_%s', $self->{ciscoEnvMonVoltageStatusIndex}),
      value => $self->{ciscoEnvMonVoltageStatusValue},
      warning => $self->{ciscoEnvMonVoltageThresholdLow},
      critical => $self->{ciscoEnvMonVoltageThresholdHigh},
  );
}

