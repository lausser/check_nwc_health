package CheckNwcHealth::F5::Velos::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->init_subsystems([
#      ["fan_subsystem", "CheckNwcHealth::F5::Velos::Component::FanSubsystem"],
      ["temperature_subsystem", "CheckNwcHealth::F5::Velos::Component::TemperatureSubsystem"],
      ["disk_subsystem", "CheckNwcHealth::F5::Velos::Component::DiskSubsystem"],
  ]);
}   
  
sub check {
  my ($self) = @_;
  $self->check_subsystems();
  my $summary = $self->summarize_subsystems();
  if ($summary) {
    $self->reduce_messages_short($summary); 
  } else {
    $self->reduce_messages_short("hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->dump_subsystems();
}

