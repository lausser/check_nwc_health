package CheckNwcHealth::MEOS;
our @ISA = qw(CheckNwcHealth::Brocade);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_and_check_environmental_subsystem();
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_and_check_mem_subsystem("CheckNwcHealth::UCDMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub analyze_environmental_subsystem {
  my ($self) = @_;
  $self->{components}->{environmental_subsystem1} =
      CheckNwcHealth::FCMGMT::Component::EnvironmentalSubsystem->new();
  $self->{components}->{environmental_subsystem2} =
      CheckNwcHealth::FCEOS::Component::EnvironmentalSubsystem->new();
}

sub check_environmental_subsystem {
  my ($self) = @_;
  $self->{components}->{environmental_subsystem1}->check();
  $self->{components}->{environmental_subsystem2}->check();
  if ($self->check_messages()) {
    $self->clear_ok();
  }
  $self->{components}->{environmental_subsystem1}->dump()
      if $self->opts->verbose >= 2;
  $self->{components}->{environmental_subsystem2}->dump()
      if $self->opts->verbose >= 2;
}

