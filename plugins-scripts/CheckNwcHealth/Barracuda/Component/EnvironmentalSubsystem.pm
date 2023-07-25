package CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('PHION-MIB', [
      ['sensors', 'hwSensorsTable', 'CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor'],
      ['partitions', 'diskSpaceTable', 'CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Partition'],
      ['raidevents', 'raidEventsTable', 'CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::RaidEvent'],
  ]);
}


package CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->{hwSensorType} eq "temperature") {
    bless $self, "CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor::Temp";
    $self->finish();
  } elsif ($self->{hwSensorType} eq "psu-status") {
    bless $self, "CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor::PS";
    $self->finish();
  } elsif ($self->{hwSensorType} eq "fan") {
    bless $self, "CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor::Fan";
    $self->finish();
  }
}

package CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor::PS;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{hwSensorValue} = ($self->{hwSensorValue} == 1) ? "ok" : "failed";
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s status is %s',
      $self->{hwSensorName}, $self->{hwSensorValue});
  if ($self->{hwSensorValue} eq "ok") {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
}

package CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor::Temp;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{hwSensorValue} /= 1000;
  $self->{name} = $self->{hwSensorName} =~ /temperature/i ?
      $self->{hwSensorName} : $self->{hwSensorName}." Temperature";
  $self->{label} = lc $self->{hwSensorName};
  $self->{label} =~ s/Temperature//gi;
  $self->{label} =~ s/^\s+//g;
  $self->{label} =~ s/\s+$//g;
  $self->{label} =~ s/\s+/_/g;
  $self->{label} = "temp_".$self->{label};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s temperature is %.2fC',
      $self->{hwSensorName}, $self->{hwSensorValue});
  $self->set_thresholds(metric => $self->{label},
      warning => 50, critical => 60
  );
  $self->add_message($self->check_thresholds(
      metric => $self->{label},
      value => $self->{hwSensorValue},
  ));
  $self->add_perfdata(
      label => $self->{label},
      value => $self->{hwSensorValue},
  );
}

package CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Sensor::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{hwSensorName} =~ /fan/i ?
      $self->{hwSensorName} : $self->{hwSensorName}." Fan";
  $self->{label} = lc $self->{hwSensorName};
  $self->{label} =~ s/Fan//gi;
  $self->{label} =~ s/^\s+//g;
  $self->{label} =~ s/\s+$//g;
  $self->{label} =~ s/\s+/_/g;
  $self->{label} = "fan_".$self->{label};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s rpm is %.2f',
      $self->{hwSensorName}, $self->{hwSensorValue});
  $self->set_thresholds(metric => $self->{label},
      warning => "1000:5500", critical => "100:6000",
  );
  $self->add_message($self->check_thresholds(
      metric => $self->{label},
      value => $self->{hwSensorValue},
  ));
  $self->add_perfdata(
      label => $self->{label},
      value => $self->{hwSensorValue},
  );
}

package CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::Partition;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{label} = (lc $self->{partitionName})."_usage";
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "partition %s usage is %.2f%%",
      $self->{partitionName},
      $self->{partitionUsedSpacePercent}
  );
  $self->set_thresholds(metric => $self->{label},
      warning => 80, critical => 90
  );
  $self->add_message($self->check_thresholds(
      metric => $self->{label},
      value => $self->{partitionUsedSpacePercent},
  ));
  $self->add_perfdata(
      label => $self->{label},
      value => $self->{partitionUsedSpacePercent},
      uom => "%",
  );
}


package CheckNwcHealth::Barracuda::Component::EnvironmentalSubsystem::RaidEvent;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'level %s raid event: %s at %s',
      $self->{raidEventSev}, $self->{raidEventText}, $self->{raidEventTime});
  if ($self->{raidEventSev} eq "error") {
    $self->add_critical();
  } elsif ($self->{raidEventSev} eq "warning") {
    $self->add_warning();
  } elsif ($self->{raidEventSev} eq "unknown") {
    $self->add_warning();
  } else {
    $self->add_ok();
  }
}
