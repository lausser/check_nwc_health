package CheckNwcHealth::Lancom;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->implements_mib('LCOS-SX-MIB')) {
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Lancom::LCOSSX::Component::EnvironmentalSubsystem");
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Lancom::LCOSSX::Component::CpuSubsystem");
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Lancom::LCOSSX::Component::MemSubsystem");
    } else {
      $self->no_such_mode();
    }
  } elsif ($self->implements_mib('LCOS-MIB')) {
    $self->bulk_is_baeh();
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Lancom::LCOS::Component::EnvironmentalSubsystem");
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Lancom::LCOS::Component::CpuSubsystem");
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Lancom::LCOS::Component::MemSubsystem");
    } else {
      $self->no_such_mode();
    }
  } else {
    $self->no_such_model();
  }
}

