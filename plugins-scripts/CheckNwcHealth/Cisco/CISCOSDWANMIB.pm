package CheckNwcHealth::Cisco::CISCOSDWANMIB;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::IOS::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::sdwan::control::vedgecount/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Cisco::Viptela::Component::SecuritySubsystem");
  } else {
    $self->no_such_mode();
  }
}


