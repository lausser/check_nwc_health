package Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects("NETSCREEN-CHASSIS-MIB", (qw(
      sysBatteryStatus)));
  $self->get_snmp_tables("NETSCREEN-CHASSIS-MIB", [
      ['fans', 'nsFanTable', 'Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Fan'],
      ['power', 'nsPowerTable', 'Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Power'],
      ['slots', 'nsSlotTable', 'Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Slot'],
      ['temperatures', 'nsTemperatureTable', 'Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Temperature'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{fans}}, @{$self->{power}}, @{$self->{slots}}, @{$self->{temperatures}}) {
    $_->check();
  }
}


package Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf "fan %s (%s) is %s",
      $self->{nsFanId}, $self->{nsFanDesc}, $self->{nsFanStatus});
  if ($self->{nsFanStatus} eq "notInstalled") {
  } elsif ($self->{nsFanStatus} eq "good") {
    $self->add_ok();
  } elsif ($self->{nsFanStatus} eq "fail") {
    $self->add_warning();
  }
}


package Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Power;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf "power supply %s (%s) is %s",
      $self->{nsPowerId}, $self->{nsPowerDesc}, $self->{nsPowerStatus});
  if ($self->{nsPowerStatus} eq "good") {
    $self->add_ok();
  } elsif ($self->{nsPowerStatus} eq "fail") {
    $self->add_warning();
  }
}


package Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Slot;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{nsSlotSN} =~ s/^\s+//g;
}

sub check {
  my $self = shift;
  $self->add_info(sprintf "%s slot %s (%s) is %s",
      $self->{nsSlotType}, $self->{nsSlotId}, $self->{nsSlotSN}, $self->{nsSlotStatus});
  if ($self->{nsSlotStatus} eq "good") {
    $self->add_ok();
  } elsif ($self->{nsSlotStatus} eq "fail") {
    $self->add_warning();
  }
}


package Classes::Juniper::NetScreen::Component::EnvironmentalSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf "temperature %s (%s) is %sC",
      $self->{nsTemperatureId}, $self->{nsTemperatureDesc}, $self->{nsTemperatureCur});
  $self->add_ok();
  $self->add_perfdata(
      label => 'temp_'.$self->{nsTemperatureId},
      value => $self->{nsTemperatureCur},
  );
}

