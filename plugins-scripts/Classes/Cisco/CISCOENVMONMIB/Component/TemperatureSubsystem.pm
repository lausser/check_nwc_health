package Classes::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['temperatures', 'ciscoEnvMonTemperatureStatusTable', 'Classes::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem::Temperature'],
  ]);
}

package Classes::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  foreach (keys %params) {
    $self->{$_} = $params{$_};
  }
  if ($self->{ciscoEnvMonTemperatureStatusValue}) {
    bless $self, $class;
  } else {
    bless $self, $class.'::Simple';
  }
  $self->ensure_index('ciscoEnvMonTemperatureStatusIndex');
  $self->{ciscoEnvMonTemperatureLastShutdown} ||= 0;
  return $self;
}

sub check {
  my $self = shift;
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
        $self->{ciscoEnvMonTemperatureThreshold});
  }
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{ciscoEnvMonTemperatureStatusIndex}),
      value => $self->{ciscoEnvMonTemperatureStatusValue},
      warning => $self->{ciscoEnvMonTemperatureThreshold},
      critical => undef,
  );
}


package Classes::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem::Temperature::Simple;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{ciscoEnvMonTemperatureStatusIndex} ||= 0;
  $self->{ciscoEnvMonTemperatureStatusDescr} ||= 0;
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

