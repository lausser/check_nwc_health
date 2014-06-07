package Classes::Cisco::IOS::Component::TemperatureSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my $tempcnt = 0;
  foreach ($self->get_snmp_table_objects(
      'CISCO-ENVMON-MIB', 'ciscoEnvMonTemperatureStatusTable')) {
    $_->{ciscoEnvMonTemperatureStatusIndex} = $tempcnt++ if (! exists $_->{ciscoEnvMonTemperatureStatusIndex});
    push(@{$self->{temperatures}},
        Classes::Cisco::IOS::Component::TemperatureSubsystem::Temperature->new(%{$_}));
  }
}

package Classes::Cisco::IOS::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  foreach (keys %params) {
    $self->{$_} = $params{$_};
  }
  $self->{ciscoEnvMonTemperatureStatusIndex} ||= 0;
  $self->{ciscoEnvMonTemperatureLastShutdown} ||= 0;
  if ($self->{ciscoEnvMonTemperatureStatusValue}) {
    bless $self, $class;
  } else {
    bless $self, $class.'::Simple';
  }
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
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    ciscoEnvMonTemperatureStatusIndex => $params{ciscoEnvMonTemperatureStatusIndex} || 0,
    ciscoEnvMonTemperatureStatusDescr => $params{ciscoEnvMonTemperatureStatusDescr},
    ciscoEnvMonTemperatureState => $params{ciscoEnvMonTemperatureState},
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
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

