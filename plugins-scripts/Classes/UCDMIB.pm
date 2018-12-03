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
  } else {
    $self->no_such_mode();
  }
}

