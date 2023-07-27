package CheckNwcHealth::Eltex::Access;
our @ISA = qw(CheckNwcHealth::Eltex);
use strict;

# MES2100: 1 PSU, no FAN
# MES2124P: 1 PSU, 2 FAN
# MES2308: 1 PSU, no FAN
# MES2324: 1 PSU, no FAN
# MES2326: 1 PSU, no FAN
# MES2348: 1 PSU, 2 FAN

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem('CheckNwcHealth::Eltex::MES::Component::CpuSubsystem');
  } elsif ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('CheckNwcHealth::Eltex::Access::Component::EnvironmentalSubsystem');
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
