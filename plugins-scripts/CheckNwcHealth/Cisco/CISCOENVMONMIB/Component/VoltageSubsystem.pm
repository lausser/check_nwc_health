package CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::VoltageSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $index = 0;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['voltages', 'ciscoEnvMonVoltageStatusTable', 'CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::VoltageSubsystem::Voltage'],
  ]);
}

sub check {
  my ($self) = @_;
  my $errorfound = 0;
  $self->add_info('checking voltages');
  if (scalar (@{$self->{voltages}}) == 0) {
  } else {
    foreach (@{$self->{voltages}}) {
      $_->check();
    }
  }
}


package CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::VoltageSubsystem::Voltage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->ensure_index('ciscoEnvMonVoltageStatusIndex');
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

