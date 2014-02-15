package Classes::CiscoAsyncOS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::CiscoAsyncOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::CiscoAsyncOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::CiscoAsyncOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::licenses::/) {
    $self->analyze_and_check_key_subsystem("Classes::CiscoAsyncOS::Component::KeySubsystem");
  } else {
    $self->no_such_mode();
  }
}

