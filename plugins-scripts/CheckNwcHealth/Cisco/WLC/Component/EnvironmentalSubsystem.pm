package CheckNwcHealth::Cisco::WLC::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{ps1_present} = $self->get_snmp_object(
      'AIRESPACE-SWITCHING-MIB', 'agentSwitchInfoPowerSupply1Present', 0);
  $self->{ps1_operational} = $self->get_snmp_object(
      'AIRESPACE-SWITCHING-MIB', 'agentSwitchInfoPowerSupply1Operational', 0);
  $self->{ps2_present} = $self->get_snmp_object(
      'AIRESPACE-SWITCHING-MIB', 'agentSwitchInfoPowerSupply2Present', 0);
  $self->{ps2_operational} = $self->get_snmp_object(
      'AIRESPACE-SWITCHING-MIB', 'agentSwitchInfoPowerSupply2Operational', 0);
  $self->{temp_environment} = $self->get_snmp_object(
      'AIRESPACE-WIRELESS-MIB', 'bsnOperatingTemperatureEnvironment', 0);
  $self->{temp_value} = $self->get_snmp_object(
      'AIRESPACE-WIRELESS-MIB', 'bsnSensorTemperature', 0);
  $self->{temp_alarm_low} = $self->get_snmp_object(
      'AIRESPACE-WIRELESS-MIB', 'bsnTemperatureAlarmLowLimit', 0);
  $self->{temp_alarm_high} = $self->get_snmp_object(
      'AIRESPACE-WIRELESS-MIB', 'bsnTemperatureAlarmHighLimit', 0);
}

sub check {
  my ($self) = @_;
  #$self->blacklist('t', $self->{cpmCPUTotalPhysicalIndex});
  my $tinfo = sprintf 'temperature is %.2fC (%s env %s-%s)',
      $self->{temp_value}, $self->{temp_environment},
      $self->{temp_alarm_low}, $self->{temp_alarm_high};
  $self->set_thresholds(
      warning => $self->{temp_alarm_low}.':'.$self->{temp_alarm_high},
      critical => $self->{temp_alarm_low}.':'.$self->{temp_alarm_high});
  $self->add_message($self->check_thresholds($self->{temp_value}), $tinfo);
  $self->add_perfdata(
      label => 'temperature',
      value => $self->{temp_value},
  );
  if ($self->{ps1_present} eq "true") {
    if ($self->{ps1_operational} ne "true") {
      $self->add_warning("Powersupply 1 is not operational");
    }
  }
  if ($self->{ps2_present} eq "true") {
    if ($self->{ps2_operational} ne "true") {
      $self->add_warning("Powersupply 2 is not operational");
    }
  }
  my $p1info = sprintf "PS1 is %spresent and %soperational",
      $self->{ps1_present} eq "true" ? "" : "not ",
      $self->{ps1_operational} eq "true" ? "" : "not ";
  my $p2info = sprintf "PS2 is %spresent and %soperational",
      $self->{ps2_present} eq "true" ? "" : "not ",
      $self->{ps2_operational} eq "true" ? "" : "not ";
  $self->add_info($tinfo.", ".$p1info.", ".$p2info);
}

sub dump {
  my ($self) = @_;
  printf "[TEMPERATURE]\n";
  foreach (qw(temp_environment temp_value temp_alarm_low temp_alarm_high)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "[PS1]\n";
  foreach (qw(ps1_present ps1_operational)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "[PS2]\n";
  foreach (qw(ps2_present ps2_operational)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

