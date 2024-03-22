package CheckNwcHealth::SkyHigh::SWG;
our @ISA = qw(CheckNwcHealth::F5);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::INTELSERVERBASEBOARD7::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::CpuSubsystem");
    $self->analyze_and_check_and_check_load_subsystem("CheckNwcHealth::UCDMIB::Component::LoadSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_and_check_mem_subsystem("CheckNwcHealth::UCDMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

