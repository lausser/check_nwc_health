package CheckNwcHealth::Audiocodes::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

  sub init {
   my ($self) = @_;
    $self->init_subsystems([
        ["temperature_subsystem", "CheckNwcHealth::Audiocodes::Component::TemperatureSubsystem"],
        ["fan_subsystem", "CheckNwcHealth::Audiocodes::Component::FanSubsystem"],
        ["powersupply_subsystem", "CheckNwcHealth::Audiocodes::Component::PowersupplySubsystem"],
        ["disk_subsystem", "CheckNwcHealth::Audiocodes::Component::DiskSubsystem"],
        ["fru_subsystem", "CheckNwcHealth::Audiocodes::Component::FruSubsystem"],
        ["alarm_subsystem", "CheckNwcHealth::Audiocodes::Component::AlarmSubsystem"],
    ]);
 }

sub check {
  my ($self) = @_;
  $self->check_subsystems();
  $self->reduce_messages_short("environmental hardware working fine")
      if ! $self->opts->subsystem;
}

sub dump {
  my ($self) = @_;
  $self->dump_subsystems();
}
