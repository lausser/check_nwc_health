package CheckNwcHealth::DrayTek::Vigor;
our @ISA = qw(CheckNwcHealth::DrayTek);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::DrayTek::Vigor::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::DrayTek::Vigor::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::DrayTek::Vigor::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

