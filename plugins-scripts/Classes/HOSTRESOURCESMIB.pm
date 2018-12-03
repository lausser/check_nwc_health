package Classes::HOSTRESOURCESMIB;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_environmental_subsystem("Classes::LMSENSORSMIB::Component::EnvironmentalSubsystem");
    if (! $self->check_messages()) {
      $self->reduce_messages("hardware working fine");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::HOSTRESOURCESMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

