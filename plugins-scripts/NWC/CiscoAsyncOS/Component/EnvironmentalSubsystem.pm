package NWC::CiscoAsyncOS::Component::EnvironmentalSubsystem;
our @ISA = qw(NWC::CiscoAsyncOS);

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
    raid_subsystem => undef,
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
      NWC::CiscoAsyncOS::Component::FanSubsystem->new(%params);
  $self->{temperature_subsystem} =
      NWC::CiscoAsyncOS::Component::TemperatureSubsystem->new(%params);
  $self->{powersupply_subsystem} = 
      NWC::CiscoAsyncOS::Component::SupplySubsystem->new(%params);
  $self->{raid_subsystem} = 
      NWC::CiscoAsyncOS::Component::RaidSubsystem->new(%params);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  $self->{raid_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
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
