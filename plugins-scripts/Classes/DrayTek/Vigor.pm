package Classes::DrayTek::Vigor;
our @ISA = qw(Classes::DrayTek);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::DrayTek::Vigor::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::DrayTek::Vigor::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::DrayTek::Vigor::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

