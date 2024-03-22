package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('INTEL-SERVER-BASEBOARD7', qw(
      systemManagementInfoOverallStatusHealth
      chassisThermalState chassisPowerState 
  ));
  $self->get_snmp_tables('INTEL-SERVER-BASEBOARD7', [
      ['processors', 'processorDeviceTable', 'CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::Processor'],
      ['powerunits', 'powerUnitTable', 'CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PowerUnit'],
      ['powersupplies', 'powerSupplyTable', 'CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PowerSupply'],
      ['physicalmemoryarrays', 'physicalMemoryArrayTable', 'CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PhysicalMemoryArray'],
      ['physicalmemories', 'physicalMemoryDeviceTable', 'CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PhysicalMemoryDevice'],
      ['coolingdevices', 'coolingDeviceTable', 'CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::CoolingDevice'],
      ['temperatures', 'temperatureProbeTable', 'CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::TemperatureProbe'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  $self->reduce_message("hardware working fine");
  $self->add_info(sprintf "overall status is %s, power state is %s, thermal state is %s",
      $self->{systemManagementInfoOverallStatusHealth},
      $self->{chassisPowerState},
      $self->{chassisThermalState});
  if ($self->{systemManagementInfoOverallStatusHealth} ne
      "healthy") {
    $self->add_critical();
  }
  if ($self->{chassisPowerState} ne "on") {
    $self->add_critical();
  }
  if ($self->{chassisThermalState} ne "healthy") {
    $self->add_warning();
  }
  if (! $self->check_messages()) {
    $self->add_ok()
  }
}

package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::Processor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s is %s",
      $self->{processorDescription},
      $self->{processorStatus});
  if ($self->{processorStatus} eq "healthy") {
  } elsif ($self->{processorStatus} eq "warning") {
    $self->add_warning();
  } elsif ($self->{processorStatus} eq "critical") {
    $self->add_critical();
  }
}


package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PowerUnit;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s is %s",
      $self->{powerUnitDescription},
      $self->{powerUnitStatus});
  if ($self->{powerUnitStatus} eq "healthy") {
  } elsif ($self->{powerUnitStatus} eq "warning") {
    $self->add_warning();
  } elsif ($self->{powerUnitStatus} eq "critical") {
    $self->add_critical();
  }
}


package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PowerSupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s is %s",
      $self->{powerSupplyDescription},
      $self->{powerSupplyStatus});
  if ($self->{powerSupplyStatus} eq "healthy") {
  } elsif ($self->{powerSupplyStatus} eq "warning") {
    $self->add_warning();
  } elsif ($self->{powerSupplyStatus} eq "critical") {
    $self->add_critical();
  }
}


package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PhysicalMemoryArray;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s status is %s",
      $self->{physicalMemoryArrayTag},
      $self->{physicalMemoryArrayStatus});
  if ($self->{physicalMemoryArrayStatus} eq "healthy") {
  } elsif ($self->{physicalMemoryArrayStatus} eq "warning") {
    $self->add_warning();
  } elsif ($self->{physicalMemoryArrayStatus} eq "critical") {
    $self->add_critical();
  }
}


package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::PhysicalMemoryDevice;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s status is %s",
      $self->{physicalMemoryDeviceLocator},
      $self->{physicalMemoryDeviceStatus});
  if ($self->{physicalMemoryDeviceStatus} eq "healthy") {
  } elsif ($self->{physicalMemoryDeviceStatus} eq "warning") {
    $self->add_warning();
  } elsif ($self->{physicalMemoryDeviceStatus} eq "critical") {
    $self->add_critical();
  }
}


package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::CoolingDevice;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  return if $self->{coolingDeviceStatus} eq "unavaiable";
  $self->add_info(sprintf "%s status is %s",
      $self->{coolingDeviceDescription},
      $self->{coolingDeviceStatus});
  if ($self->{coolingDeviceStatus} eq "healthy") {
  } elsif ($self->{coolingDeviceStatus} eq "warning") {
    $self->add_warning();
  } elsif ($self->{coolingDeviceStatus} eq "critical") {
    $self->add_critical();
  }
}


package CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem::TemperatureProbe;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->{temperatureReading} == 0 ||
      $self->{temperatureReading} == 2147483647) {
    $self->{valid} = 0;
  } else {
    $self->{valid} = 1;
    my $factor = $self->{temperatureResolution} * 1 / (10 * 10);
    $self->{temperatureReading} *= $factor;
  }
  $self->{valid} = 0 if $self->{temperatureStatus} eq "unavailable";
}

sub check {
  my ($self) = @_;
  return if ! $self->{valid};
  $self->add_info(sprintf "%s status is %s",
      $self->{temperatureDescription},
      $self->{temperatureStatus});
  if ($self->{temperatureStatus} ne "healthy") {
    $self->add_warning();
  }
}



