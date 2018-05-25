package Classes::FabOS;
our @ISA = qw(Classes::Brocade);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::FabOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::FabOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::FabOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem("Classes::FabOS::Component::InterfaceSubsystem");
  } else {
    $self->no_such_mode();
  }
}

