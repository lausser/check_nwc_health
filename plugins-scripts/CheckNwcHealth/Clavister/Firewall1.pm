package CheckNwcHealth::Clavister::Firewall1;
our @ISA = qw(CheckNwcHealth::Clavister);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Clavister::Firewall1::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Clavister::Firewall1::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Clavister::Firewall1::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

