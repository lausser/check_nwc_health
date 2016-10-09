package Classes::Cisco::SB;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Cisco::SB::Component::EnvironmentalSubsystem");
    if (! $self->check_messages()) {
      $self->clear_messages(0);
      $self->add_ok("environmental hardware working fine");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Cisco::SB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->no_such_mode();
    #$self->analyze_and_check_environmental_subsystem("Classes::Cisco::SB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

