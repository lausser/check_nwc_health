package Classes::Cumulus;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::LMSENSORSMIB::Component::EnvironmentalSubsystem");
  } else {
    $self->no_such_mode();
  }
}

