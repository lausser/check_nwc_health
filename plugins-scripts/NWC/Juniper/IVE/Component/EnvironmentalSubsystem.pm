package NWC::Juniper::IVE::Component::EnvironmentalSubsystem;
our @ISA = qw(NWC::SGOS);

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
    sensor_subsystem => undef,
    disk_subsystem => undef,
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
  $self->{disk_subsystem} =
      NWC::Juniper::IVE::Component::DiskSubsystem->new(%params);
  foreach (qw(iveTemperature fanDescription psDescription raidDescription)) {
    $self->{$_} = $self->get_snmp_object('JUNIPER-IVE-MIB', $_);
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{disk_subsystem}->check();
  $self->add_info(sprintf "temperature is %.2f deg", $self->{iveTemperature});
  $self->set_thresholds(warning => 70, critical => 75);
  $self->check_thresholds(0);
  $self->add_perfdata(
      label => 'temperature',
      value => $self->{iveTemperature},
      warning => $self->{warning},
      critical => $self->{critical},
  );
  if ($self->{fanDescription} && $self->{fanDescription} =~ /(failed)|(threshold)/) {
    $self->add_message(CRITICAL, $self->{fanDescription});
  }
  if ($self->{psDescription} && $self->{psDescription} =~ /failed/) {
    $self->add_message(CRITICAL, $self->{psDescription});
  }
  if ($self->{raidDescription} && $self->{raidDescription} =~ /(failed)|(unknown)/) {
    $self->add_message(CRITICAL, $self->{raidDescription});
  }
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{disk_subsystem}->dump();
}

1;
