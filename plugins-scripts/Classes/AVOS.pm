package Classes::AVOS;
our @ISA = qw(Classes::Bluecoat);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::AVOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::AVOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::licenses::/) {
    $self->analyze_and_check_key_subsystem("Classes::AVOS::Component::KeySubsystem");
  } elsif ($self->mode =~ /device::connections/) {
    $self->analyze_and_check_connection_subsystem("Classes::AVOS::Component::ConnectionSubsystem");
  } elsif ($self->mode =~ /device::security/) {
    $self->analyze_and_check_security_subsystem("Classes::AVOS::Component::SecuritySubsystem");
  } else {
    $self->no_such_mode();
  }
}

