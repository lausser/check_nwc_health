package Classes::Juniper::IVE;
our @ISA = qw(Classes::Juniper);
use strict;

use constant trees => (
  '1.3.6.1.2.1',        # mib-2
  '1.3.6.1.2.1.105',
);

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Juniper::IVE::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Juniper::IVE::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Juniper::IVE::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::users/) {
    $self->analyze_and_check_user_subsystem("Classes::Juniper::IVE::Component::UserSubsystem");
  } else {
    $self->no_such_mode();
  }
}

