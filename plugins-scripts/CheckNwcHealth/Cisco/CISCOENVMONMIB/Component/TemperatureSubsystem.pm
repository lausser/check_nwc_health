package CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['temperatures', 'ciscoEnvMonTemperatureStatusTable', 'CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem::Temperature', sub { my ($o) = @_; return ($o->{ciscoEnvMonTemperatureState} eq "notPresent" or $o->{ciscoEnvMonTemperatureState} eq "notFunctioning") ? 0 : 1 }],
  ]);
}

package CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if (! exists $self->{ciscoEnvMonTemperatureStatusValue}) {
    bless $self, ref($self).'::Simple';
  }
  $self->ensure_index('ciscoEnvMonTemperatureStatusIndex');
  $self->{ciscoEnvMonTemperatureLastShutdown} ||= 0;
  $self->{ciscoEnvMonTemperatureStatusValue} -= 255 if
      exists $self->{ciscoEnvMonTemperatureStatusValue} and
      defined $self->{ciscoEnvMonTemperatureStatusValue} and
      $self->{ciscoEnvMonTemperatureStatusValue} > 200;
  # ciscoEnvMonTemperatureStatusValue may not exist. it surely doesn't
  # if ciscoEnvMonTemperatureState = notPresent. We finish() before we
  # filter in get_snmp_tables
}

sub check {
  my ($self) = @_;
  if ($self->{ciscoEnvMonTemperatureState} eq "notFunctioning") {
    $self->add_info(sprintf "temperature sensor %s is not functioning",
        $self->{ciscoEnvMonTemperatureStatusIndex});
    # DRECK!!!!!! $self->add_warning();
    # das fuehrt zu mehreren Tausend Fehlern wegen
    # [TEMPERATURE_2159]
    # ciscoEnvMonTemperatureLastShutdown: 0
    # ciscoEnvMonTemperatureState: notFunctioning
    # ciscoEnvMonTemperatureStatusDescr: Te2/0/17 Receive Power Sensor, NOT FUNCTIONING 
    # ciscoEnvMonTemperatureStatusIndex: 2159
    # ciscoEnvMonTemperatureStatusValue: 0
    # ciscoEnvMonTemperatureThreshold: 0
    # info: temperature sensor %s is not functioning
  } elsif ($self->{ciscoEnvMonTemperatureStatusValue} >
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
    $self->add_ok();
  }
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{ciscoEnvMonTemperatureStatusIndex}),
      value => $self->{ciscoEnvMonTemperatureStatusValue},
      warning => $self->{ciscoEnvMonTemperatureThreshold},
      critical => undef,
  );
}


package CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem::Temperature::Simple;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
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
    $self->add_ok();
  }
}

