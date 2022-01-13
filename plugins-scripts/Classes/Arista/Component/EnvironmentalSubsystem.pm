package Classes::Arista::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable',
      'Classes::Arista::Component::EnvironmentalSubsystem::Entity',
      undef,
      ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']
    ],
  ]);
  $self->get_snmp_tables('ENTITY-SENSOR-MIB', [
    ['sensorvalues', 'entPhySensorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  $self->get_snmp_tables('ENTITY-STATE-MIB', [
    ['sensorstates', 'entStateTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  $self->get_snmp_tables('ARISTA-ENTITY-SENSOR-MIB', [
    ['sensorthresholds', 'aristaEntSensorThresholdTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  $self->merge_tables("entities", "sensorvalues", "sensorstates", "sensorthresholds");
  foreach (@{$self->{entities}}) {
    $_->rebless();
    $_->finish() if $_->can('finish');
  }
  @{$self->{entities}} = grep {
    ! exists $_->{valid} || $_->{valid};
  } @{$self->{entities}};
}

package Classes::Arista::Component::EnvironmentalSubsystem::Entity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


sub rebless {
  my ($self) = @_;
  bless $self,
      'Classes::Arista::Component::EnvironmentalSubsystem::Chassis' if
      $self->{entPhysicalClass} eq 'chassis';
  bless $self,
      'Classes::Arista::Component::EnvironmentalSubsystem::Container' if
      $self->{entPhysicalClass} eq 'container';
  bless $self,
      'Classes::Arista::Component::EnvironmentalSubsystem::Fan' if
      $self->{entPhysicalClass} eq 'fan';
  bless $self,
      'Classes::Arista::Component::EnvironmentalSubsystem::Module' if
      $self->{entPhysicalClass} eq 'module';
  bless $self,
      'Classes::Arista::Component::EnvironmentalSubsystem::Port' if
      $self->{entPhysicalClass} eq 'port';
  bless $self,
      'Classes::Arista::Component::EnvironmentalSubsystem::Powersupply' if
      $self->{entPhysicalClass} eq 'powerSupply';
  bless $self,
      'Classes::Arista::Component::EnvironmentalSubsystem::Sensor' if
      $self->{entPhysicalClass} eq 'sensor';
}

sub check_state {
  my ($self) = @_;
  $self->add_info(sprintf "%s is %s (admin %s, oper %s)",
      $self->{entPhysicalDescr}, $self->{entStateUsage},
      $self->{entStateAdmin}, $self->{entStateOper});
  if ($self->{entStateAdmin} eq "unlocked") {
    if ($self->{entStateOper} eq "enabled") {
      if ($self->{entStateUsage} eq "idle") {
        $self->add_ok();
      } elsif ($self->{entStateUsage} eq "active") {
        $self->add_ok();
      } elsif ($self->{entStateUsage} eq "busy") {
        $self->add_warning();
      } else {
        $self->add_unknown();
      }
    } elsif ($self->{entStateOper} eq "disabled") {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
  } elsif ($self->{entStateOper} ne "enabled" and $self->{entStateStandby} eq "providingService" and exists $self->{entPhySensorValue} and $self->{entPhySensorValue}) {
    $self->add_critical();
  } else {
    $self->add_ok(); # admin disabled, ignore
  }
}

package Classes::Arista::Component::EnvironmentalSubsystem::Chassis;
our @ISA = qw(Classes::Arista::Component::EnvironmentalSubsystem::Entity);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Container;
our @ISA = qw(Classes::Arista::Component::EnvironmentalSubsystem::Entity);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Classes::Arista::Component::EnvironmentalSubsystem::Entity);
use strict;

sub check {
  my ($self) = @_;
  $self->check_state();
}

package Classes::Arista::Component::EnvironmentalSubsystem::Module;
our @ISA = qw(Classes::Arista::Component::EnvironmentalSubsystem::Entity);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Port;
our @ISA = qw(Classes::Arista::Component::EnvironmentalSubsystem::Entity);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Powersupply;
our @ISA = qw(Classes::Arista::Component::EnvironmentalSubsystem::Entity);
use strict;

sub check {
  my ($self) = @_;
  $self->check_state();
}

sub check_state {
  my ($self) = @_;
  $self->SUPER::check_state();
  if ($self->{entStateOper} eq "unknown" and $self->{entStateAdmin} eq "unknown" and $self->{entStateStandby} eq "providingService") {
    $self->add_critical_mitigation("plug has been pulled");
  }
}

package Classes::Arista::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Classes::Arista::Component::EnvironmentalSubsystem::Entity);
use strict;

sub finish {
  my ($self) = @_;
  
  $self->{valid} = ($self->{entPhySensorValue} == -1000000000 || $self->{entPhySensorValue} == 1000000000)
      ? 0 : 1;
  foreach (qw(entPhySensorValue
      aristaEntSensorThresholdLowWarning aristaEntSensorThresholdHighWarning
      aristaEntSensorThresholdLowCritical aristaEntSensorThresholdHighCritical)) {
    delete $self->{$_} if defined $self->{$_} && $_ ne 'entPhySensorValue' &&
        ($self->{$_} == -1000000000 || $self->{$_} == 1000000000);
    if ($self->{entPhySensorPrecision} && $self->{$_}) {
      $self->{$_} /= 10 ** $self->{entPhySensorPrecision};
    }
  }
}

sub check {
  my ($self) = @_;
  $self->check_state();
  my ($warn, $crit) = (undef, undef);
  if ($self->{aristaEntSensorStatusDescr} =~ /no thresholds/i) {
  } else {
    $warn =
        ($self->{aristaEntSensorThresholdLowWarning} ?
        $self->{aristaEntSensorThresholdLowWarning} : '').':'.
        ($self->{aristaEntSensorThresholdHighWarning} ?
        $self->{aristaEntSensorThresholdHighWarning} : '');
    $crit =
        ($self->{aristaEntSensorThresholdLowCritical} ?
        $self->{aristaEntSensorThresholdLowCritical} : '').':'.
        ($self->{aristaEntSensorThresholdHighCritical} ?
        $self->{aristaEntSensorThresholdHighCritical} : '');
    $warn = undef if $warn eq ':';
    $crit = undef if $crit eq ':';
  }
  $self->add_thresholds(metric => $self->{entPhysicalDescr}.'_'.$self->{entPhySensorUnitsDisplay},
      warning => $warn, critical => $crit);
  $self->add_perfdata(
      label => $self->{entPhysicalDescr}.'_'.$self->{entPhySensorUnitsDisplay},
      value => $self->{entPhySensorValue},
      warning => $warn, critical => $crit,
  );
}

__END__
Stecker gezogen
[POWERSUPPLY_100721000]
entPhysicalClass: powerSupply
entPhysicalDescr: PowerSupply2
entPhysicalName:
entStateAdmin: unknown
entStateLastChanged:
entStateOper: unknown
entStateStandby: providingService <-kein failover, der das hier sichert
entStateUsage: active

