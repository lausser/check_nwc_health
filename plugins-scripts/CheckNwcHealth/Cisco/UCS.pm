package CheckNwcHealth::Cisco::UCS;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::UCS::Component::EnvironmentalSubsystem");
  } else {
    $self->no_such_mode();
  }
}


