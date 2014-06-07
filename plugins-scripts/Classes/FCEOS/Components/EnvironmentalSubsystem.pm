package Classes::FCEOS::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub overall_init {
  my $self = shift;
  $self->get_snmp_objects('FCEOS-MIB', (qw(
      fcEosSysOperStatus)));
}

sub init {
  my $self = shift;
  $self->{fru_subsystem} =
      Classes::FCEOS::Component::FruSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{fru_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  } else {
    if ($self->{fcEosSysOperStatus} eq "operational") {
      $self->clear_critical();
      $self->clear_warning();
    } elsif ($self->{fcEosSysOperStatus} eq "major-failure") {
      $self->add_critical("major device failure");
    } else {
      $self->add_warning($self->{fcEosSysOperStatus});
    }
  }
}

