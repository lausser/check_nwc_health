package Classes::Cisco::AsyncOS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Cisco::AsyncOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Cisco::AsyncOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::AsyncOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::licenses::/) {
    $self->analyze_and_check_key_subsystem("Classes::Cisco::AsyncOS::Component::KeySubsystem");
  } else {
    $self->no_such_mode();
  }
}

