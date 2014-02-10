package Classes::CiscoIOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::CiscoIOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    condition => $params{condition},
    status => $params{status},
    fan_subsystem => undef,
    temperature_subsystem => undef,
    powersupply_subsystem => undef,
    voltage_subsystem => undef,
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  #
  # 1.3.6.1.4.1.9.9.13.1.1.0 ciscoEnvMonPresent (irgendein typ of envmon)
  # 
  $self->{fan_subsystem} =
      Classes::CiscoIOS::Component::FanSubsystem->new(%params);
  $self->{temperature_subsystem} =
      Classes::CiscoIOS::Component::TemperatureSubsystem->new(%params);
  $self->{powersupply_subsystem} = 
      Classes::CiscoIOS::Component::SupplySubsystem->new(%params);
  $self->{voltage_subsystem} =
      Classes::CiscoIOS::Component::VoltageSubsystem->new(%params);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{voltage_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{voltage_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
}

1;
