package CheckNwcHealth::Fortinet::Fortigate;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Fortinet::Fortigate::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Fortinet::Fortigate::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Fortinet::Fortigate::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Fortinet::Fortigate::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::vpn::/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Fortinet::Fortigate::Component::VpnSubsystem");
  } elsif ($self->mode =~ /device::vrrp/) {
    $self->analyze_and_check_vrrp_subsystem("CheckNwcHealth::Fortinet::Fortigate::Component::VrrpSubsystem");
  } else {
    $self->no_such_mode();
  }
}

