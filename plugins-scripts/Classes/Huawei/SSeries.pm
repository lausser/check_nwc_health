package Classes::Huawei::SSeries;
our @ISA = qw(Classes::Huawei);
use strict;

sub init {
  my ($self) = @_;

  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Huawei::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Huawei::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Huawei::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

__END__
