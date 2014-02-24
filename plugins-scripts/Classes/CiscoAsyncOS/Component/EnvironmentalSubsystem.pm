package Classes::CiscoAsyncOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::CiscoAsyncOS);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  #
  # 1.3.6.1.4.1.9.9.13.1.1.0 ciscoEnvMonPresent (irgendein typ of envmon)
  # 
  $self->{fan_subsystem} =
      Classes::CiscoAsyncOS::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::CiscoAsyncOS::Component::TemperatureSubsystem->new();
  $self->{powersupply_subsystem} = 
      Classes::CiscoAsyncOS::Component::SupplySubsystem->new();
  $self->{raid_subsystem} = 
      Classes::CiscoAsyncOS::Component::RaidSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  $self->{raid_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
  $self->{raid_subsystem}->dump();
}

1;
