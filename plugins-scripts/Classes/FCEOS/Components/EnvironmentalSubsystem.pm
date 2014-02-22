package Classes::FCEOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::FCEOS);
use strict;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->overall_init();
  $self->init();
  return $self;
}


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
      $self->clear_messages(CRITICAL);
      $self->clear_messages(WARNING);
    } elsif ($self->{fcEosSysOperStatus} eq "major-failure") {
      $self->add_critical("major device failure");
    } else {
      $self->add_warning($self->{fcEosSysOperStatus});
    }
  }
}

