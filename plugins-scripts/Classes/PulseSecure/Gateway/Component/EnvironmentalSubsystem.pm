package Classes::PulseSecure::Gateway::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{disk_subsystem} =
      Classes::PulseSecure::Gateway::Component::DiskSubsystem->new();
  $self->get_snmp_objects('PULSESECURE-PSG-MIB', (qw(
      iveTemperature fanDescription psDescription)));
}

sub check {
  my ($self) = @_;
  $self->{disk_subsystem}->check();
  $self->add_info(sprintf "temperature is %.2f deg", $self->{iveTemperature});
  $self->set_thresholds(warning => 70, critical => 75);
  $self->check_thresholds(0);
  $self->add_perfdata(
      label => 'temperature',
      value => $self->{iveTemperature},
      warning => $self->{warning},
      critical => $self->{critical},
  ) if $self->{iveTemperature};
  if ($self->{fanDescription} && $self->{fanDescription} =~ /(failed)|(threshold)/i) {
    $self->add_critical($self->{fanDescription});
  }
  if ($self->{psDescription} && $self->{psDescription} =~ /failed/i) {
    $self->add_critical($self->{psDescription});
  }
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{disk_subsystem}->dump();
}

