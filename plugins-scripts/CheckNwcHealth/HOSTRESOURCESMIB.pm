package CheckNwcHealth::HOSTRESOURCESMIB;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::LMSENSORSMIB::Component::EnvironmentalSubsystem");
    if (! $self->check_messages()) {
      $self->reduce_messages("hardware working fine");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

