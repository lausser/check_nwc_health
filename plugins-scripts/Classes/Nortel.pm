package Classes::Nortel;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Nortel::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Nortel::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Nortel::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::hsrp/) {
    $self->analyze_and_check_hsrp_subsystem("Classes::HSRP::Component::HSRPSubsystem");
  } else {
    $self->no_such_mode();
  }
}

