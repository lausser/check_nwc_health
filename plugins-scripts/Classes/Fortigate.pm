package Classes::Fortigate;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Fortigate::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Fortigate::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Fortigate::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_mem_subsystem("Classes::Fortigate::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::vpn::sessions/) {
    $self->analyze_and_check_config_subsystem("Classes::Fortigate::Component::VpnSubsystem");
  } else {
    $self->no_such_mode();
  }
}

