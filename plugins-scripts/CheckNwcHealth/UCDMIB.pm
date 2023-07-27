package CheckNwcHealth::UCDMIB;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::UCDMIB::Component::DiskSubsystem");
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::LMSENSORSMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::CpuSubsystem");
    $self->analyze_and_check_load_subsystem("CheckNwcHealth::UCDMIB::Component::LoadSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::UCDMIB::Component::MemSubsystem");
    $self->analyze_and_check_swap_subsystem("CheckNwcHealth::UCDMIB::Component::SwapSubsystem");
  } elsif ($self->mode =~ /device::process::status/) {
    $self->analyze_and_check_process_subsystem("CheckNwcHealth::UCDMIB::Component::ProcessSubsystem");
  } elsif ($self->mode =~ /device::uptime/ && $self->implements_mib("HOST-RESOURCES-MIB")) {
    $self->analyze_and_check_uptime_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::UptimeSubsystem");
  } else {
    $self->no_such_mode();
  }
}

