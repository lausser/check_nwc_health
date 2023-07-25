package CheckNwcHealth::AVOS;
our @ISA = qw(CheckNwcHealth::Bluecoat);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::AVOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::AVOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::licenses::/) {
    $self->analyze_and_check_key_subsystem("CheckNwcHealth::AVOS::Component::KeySubsystem");
  } elsif ($self->mode =~ /device::connections/) {
    $self->analyze_and_check_connection_subsystem("CheckNwcHealth::AVOS::Component::ConnectionSubsystem");
  } elsif ($self->mode =~ /device::security/) {
    $self->analyze_and_check_security_subsystem("CheckNwcHealth::AVOS::Component::SecuritySubsystem");
  } else {
    $self->no_such_mode();
  }
}

