package CheckNwcHealth::Juniper::NetScreen;
our @ISA = qw(CheckNwcHealth::Juniper);
use strict;

use constant trees => (
  '1.3.6.1.2.1',        # mib-2
  '1.3.6.1.2.1.105',
);

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Juniper::NetScreen::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Juniper::NetScreen::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Juniper::NetScreen::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::ha::status/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Juniper::NetScreen::Component::VsdSubsystem");
  } else {
    $self->no_such_mode();
  }
}

