package CheckNwcHealth::Lancom::LCOSSX::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('LCOS-SX-MIB', (qw(
      lcsSystemInfoModelName
      lcsSystemInfoSystemDescript
      lcsSystemInfoFanSpeed
      lcsSystemInfoTemperature1
      lcsSystemInfoTemperature2
      lcsSystemInfoTemperature3
      lcsLMCManagementStatus
      lcsLMCControlStatus
      lcsLMCMonitoringStatus
  )));
  # lcsSystemInfoPowerStatus is commented out in the mib
  # others as well...
  $self->{lcsSystemInfoFanSpeed} =~ s/(\d+).*/$1/g;
}

sub check {
  my ($self) = @_;
  $self->add_info('checking temperature');
  # lcsSystemInfoTemperature1: 70 ... even if this is the cpu, it's high
  # lcsSystemInfoTemperature2: 40
  # lcsSystemInfoTemperature3: 47
  $self->add_info(sprintf 'temperature1 is %.2f',
      $self->{lcsSystemInfoTemperature1});
  $self->set_thresholds(
      metric => 'temperature1',
      warning => 80,
      critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => 'temperature1',
      value => $self->{lcsSystemInfoTemperature1},
  ));
  $self->add_perfdata(
      label => 'temperature1',
      value => $self->{lcsSystemInfoTemperature1},
  );
  $self->add_info(sprintf 'temperature2 is %.2f',
      $self->{lcsSystemInfoTemperature2});
  $self->set_thresholds(
      metric => 'temperature2',
      warning => 50,
      critical => 60,
  );
  $self->add_message($self->check_thresholds(
      metric => 'temperature2',
      value => $self->{lcsSystemInfoTemperature2},
  ));
  $self->add_perfdata(
      label => 'temperature2',
      value => $self->{lcsSystemInfoTemperature2},
  );
  $self->add_info(sprintf 'temperature3 is %.2f',
      $self->{lcsSystemInfoTemperature3});
  $self->set_thresholds(
      metric => 'temperature3',
      warning => 50,
      critical => 60,
  );
  $self->add_message($self->check_thresholds(
      metric => 'temperature3',
      value => $self->{lcsSystemInfoTemperature3},
  ));
  $self->add_perfdata(
      label => 'temperature3',
      value => $self->{lcsSystemInfoTemperature3},
  );
  $self->add_perfdata(
      label => 'fan_rpm',
      value => $self->{lcsSystemInfoFanSpeed},
  );
  foreach my $status (qw(
      lcsLMCManagementStatus
      lcsLMCControlStatus
      lcsLMCMonitoringStatus
  )) {
    $self->add_info(sprintf "%s is %s", $status, $self->{$status});
    if ($self->{$status} =~ /error/i) {
      $self->add_warning();
    } else {
      $self->add_ok();
    }
  }
}

