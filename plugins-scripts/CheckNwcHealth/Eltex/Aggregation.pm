package CheckNwcHealth::Eltex::Aggregation;
our @ISA = qw(CheckNwcHealth::Eltex);
use strict;

# MES2324B: 2 PSU, no FAN
# MES2324F, MES2324FB: 2 PSU, 4 FAN
# MES3108, MES3116, MES3124, MES3224: 2 PSU, 4 FAN
# MES5324: 2 PSU, 4 FAN

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem('CheckNwcHealth::Eltex::MES::Component::CpuSubsystem');
  } elsif ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckNwcHealth::Eltex::Aggregation::Component::EnvironmentalSubsystem');
    if (! $self->check_messages()) {
      $self->clear_messages(0);
      $self->add_ok('environmental hardware working fine');
    }
  } elsif ($self->mode =~ /device::ha::status/) {
    $self->analyze_and_check_ha_subsystem('CheckNwcHealth::Eltex::MES::Component::HaSubsystem');
  } else {
    $self->no_such_mode();
  }
}
