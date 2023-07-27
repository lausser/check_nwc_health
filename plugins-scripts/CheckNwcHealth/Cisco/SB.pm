package CheckNwcHealth::Cisco::SB;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::SB::Component::EnvironmentalSubsystem");
    if (! $self->check_messages()) {
      $self->clear_messages(0);
      $self->add_ok("environmental hardware working fine");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::SB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->no_such_mode();
    #$self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::SB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

