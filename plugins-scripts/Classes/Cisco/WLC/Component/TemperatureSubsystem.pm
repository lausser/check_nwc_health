package Classes::Cisco::IOS::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $tempcnt = 0;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['temperatures', 'ciscoEnvMonTemperatureStatusTable', 'Classes::Cisco::IOS::Component::TemperatureSubsystem::Temperature'],
  ]);
}

package Classes::Cisco::IOS::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{ciscoEnvMonTemperatureLastShutdown} ||= 0;
  if (! exists $self->{ciscoEnvMonTemperatureStatusIndex}) {
    $self->{ciscoEnvMonTemperatureStatusIndex} = $self->{flat_indices};
  }
  if (! exists $self->{ciscoEnvMonTemperatureStatusValue}) {
    bless $self, 'Classes::Cisco::IOS::Component::TemperatureSubsystem::Temperature::Simple';
  }
}

sub check {
  my ($self) = @_;
  if ($self->{ciscoEnvMonTemperatureStatusValue} >
      $self->{ciscoEnvMonTemperatureThreshold}) {
    $self->add_info(sprintf 'temperature %d %s is too high (%d of %d max = %s)',
        $self->{ciscoEnvMonTemperatureStatusIndex},
        $self->{ciscoEnvMonTemperatureStatusDescr},
        $self->{ciscoEnvMonTemperatureStatusValue},
        $self->{ciscoEnvMonTemperatureThreshold},
        $self->{ciscoEnvMonTemperatureState});
    if ($self->{ciscoEnvMonTemperatureState} eq 'warning') {
      $self->add_warning();
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_critical();
    }
  } else {
    $self->add_info(sprintf 'temperature %d %s is %d (of %d max = normal)',
        $self->{ciscoEnvMonTemperatureStatusIndex},
        $self->{ciscoEnvMonTemperatureStatusDescr},
        $self->{ciscoEnvMonTemperatureStatusValue},
        $self->{ciscoEnvMonTemperatureThreshold},
        $self->{ciscoEnvMonTemperatureState});
  }
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{ciscoEnvMonTemperatureStatusIndex}),
      value => $self->{ciscoEnvMonTemperatureStatusValue},
      warning => $self->{ciscoEnvMonTemperatureThreshold},
      critical => undef,
  );
}


package Classes::Cisco::IOS::Component::TemperatureSubsystem::Temperature::Simple;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'temperature %d %s is %s',
      $self->{ciscoEnvMonTemperatureStatusIndex},
      $self->{ciscoEnvMonTemperatureStatusDescr},
      $self->{ciscoEnvMonTemperatureState});
  if ($self->{ciscoEnvMonTemperatureState} ne 'normal') {
    if ($self->{ciscoEnvMonTemperatureState} eq 'warning') {
      $self->add_warning();
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_critical();
    }
  } else {
  }
}

