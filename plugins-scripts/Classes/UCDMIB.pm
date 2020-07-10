package Classes::UCDMIB;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::UCDMIB::Component::DiskSubsystem");
    $self->analyze_and_check_environmental_subsystem("Classes::LMSENSORSMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::UCDMIB::Component::CpuSubsystem");
    $self->analyze_and_check_load_subsystem("Classes::UCDMIB::Component::LoadSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::UCDMIB::Component::MemSubsystem");
    $self->analyze_and_check_swap_subsystem("Classes::UCDMIB::Component::SwapSubsystem");
  } elsif ($self->mode =~ /device::process::status/) {
    $self->analyze_and_check_process_subsystem("Classes::UCDMIB::Component::ProcessSubsystem");
  } elsif ($self->mode =~ /device::uptime/ && $self->implements_mib("HOST-RESOURCES-MIB")) {
    $self->analyze_and_check_uptime_subsystem("Classes::HOSTRESOURCESMIB::Component::UptimeSubsystem");
  } else {
    $self->no_such_mode();
  }
}

