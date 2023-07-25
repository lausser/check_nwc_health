package CheckNwcHealth::CheckPoint::Gaia;
our @ISA = qw(CheckNwcHealth::CheckPoint::Firewall1);
use strict;

sub xinit {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::CheckPoint::Firewall1::Component::EnvironmentalSubsystem");
    $self->no_such_mode();
  }
}

