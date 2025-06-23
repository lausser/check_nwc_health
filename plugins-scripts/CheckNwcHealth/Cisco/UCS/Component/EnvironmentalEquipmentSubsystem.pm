package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-UNIFIED-COMPUTING-EQUIPMENT-MIB', [
      ['fans', 'cucsEquipmentFanTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem::Fan'],
      ['powersupplies', 'cucsEquipmentPsuTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem::Powersupply'],
      ['healthleds', 'cucsEquipmentHealthLedTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem::HealthLed'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  $self->subsystem_summary(join(", ", (
    sprintf("%d fans checked", scalar(@{$self->{fans}})),
    sprintf("%d powersupplies checked", scalar(@{$self->{powersupplies}})),
    sprintf("%d leds checked", scalar(@{$self->{healthleds}})),
  )));
}

package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsEquipmentFanPresence} eq "missing") {
    return;
  }
  $self->add_info(sprintf "%s is %s",
      $self->{cucsEquipmentFanDn},
      $self->{cucsEquipmentFanOperState}
  );
  if ($self->{cucsEquipmentFanOperState} eq "operable") {
    $self->add_ok();
  } else {
    $self->add_warning();
  }
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsEquipmentPsuPresence} eq "missing") {
    return;
  }
  $self->add_info(sprintf "%s is %s",
      $self->{cucsEquipmentPsuDn},
      $self->{cucsEquipmentPsuOperState}
  );
  if ($self->{cucsEquipmentPsuOperState} eq "operable") {
    $self->add_ok();
  } else {
    $self->add_warning();
  }
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem::HealthLed;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s is %s/%s",
      $self->{cucsEquipmentHealthLedName},
      $self->{cucsEquipmentHealthLedHealthLedState},
      $self->{cucsEquipmentHealthLedColor},
  );
  if ($self->{cucsEquipmentHealthLedHealthLedState} eq "normal") {
    $self->add_ok();
  } elsif ($self->{cucsEquipmentHealthLedHealthLedState} eq "minor") {
    $self->add_warning();
  } else {
    $self->add_critical();
  }
}


