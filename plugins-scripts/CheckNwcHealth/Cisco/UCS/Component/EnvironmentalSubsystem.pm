package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;


sub init {
  my ($self) = @_;
  $self->init_subsystems([
      ["cpu_subsystem", "CheckNwcHealth::Cisco::UCS::Component::EnvironmentalCpuSubsystem"],
      ["mem_subsystem", "CheckNwcHealth::Cisco::UCS::Component::EnvironmentalMemSubsystem"],
      ["rackunit_subsystem", "CheckNwcHealth::Cisco::UCS::Component::EnvironmentalRackUnitSubsystem"],
      ["equipment_subsystem", "CheckNwcHealth::Cisco::UCS::Component::EnvironmentalEquipmentSubsystem"],
      ["storage_subsystem", "CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem"],
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

