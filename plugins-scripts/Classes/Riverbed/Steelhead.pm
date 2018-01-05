package Classes::Riverbed::Steelhead;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Riverbed::Steelhead::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Server::Linux::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::disk::usage/) {
    $self->analyze_and_check_disk_subsystem("Classes::UCDMIB::Component::DiskSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Server::Linux::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::process::status/) {
    $self->analyze_and_check_process_subsystem("Classes::UCDMIB::Component::ProcessSubsystem");
  } elsif ($self->mode =~ /device::uptime/) {
    $self->analyze_and_check_uptime_subsystem("Classes::HOSTRESOURCESMIB::Component::UptimeSubsystem");
  } else {
    $self->no_such_mode();
  }
}


package Classes::Riverbed::SteelheadEX;
our @ISA = qw(Classes::Riverbed::Steelhead);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Riverbed::SteelheadEX::Component::EnvironmentalSubsystem");
  } else {
    $self->SUPER::init();
  }
}

