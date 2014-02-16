package Classes::CiscoWLC;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::CiscoWLC::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::CiscoWLC::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::CiscoWLC::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::wlan/) {
    $self->analyze_and_check_wlan_subsystem("Classes::CiscoWLC::Component::WlanSubsystem");
  } else {
    $self->no_such_mode();
  }
}

