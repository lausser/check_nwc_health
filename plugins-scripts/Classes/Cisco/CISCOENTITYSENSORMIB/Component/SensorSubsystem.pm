package Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $sensors = {};
  $self->get_snmp_tables('CISCO-ENTITY-SENSOR-MIB', [
    ['sensors', 'entSensorValueTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::Sensor', sub { my ($o) = @_; $self->filter_name($o->{entPhysicalIndex})}],
    ['thresholds', 'entSensorThresholdTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::SensorThreshold'],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::PhysicalEntity'],
  ]);
  @{$self->{sensor_entities}} = grep { $_->{entPhysicalClass} eq 'sensor' } @{$self->{entities}};
  foreach my $sensor (@{$self->{sensors}}) {
    $sensors->{$sensor->{entPhysicalIndex}} = $sensor;
    foreach my $threshold (@{$self->{thresholds}}) {
      if ($sensor->{entPhysicalIndex} eq $threshold->{entPhysicalIndex}) {
        push(@{$sensor->{thresholds}}, $threshold);
      }
    }
    foreach my $entity (@{$self->{sensor_entities}}) {
      if ($sensor->{entPhysicalIndex} eq $entity->{entPhysicalIndex}) {
        $sensor->{entity} = $entity;
      }
    }
  }
}

package Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  $self->{entPhysicalIndex} = $self->{flat_indices};
  # www.thaiadmin.org%2Fboard%2Findex.php%3Faction%3Ddlattach%3Btopic%3D45832.0%3Battach%3D23494&ei=kV9zT7GHJ87EsgbEvpX6DQ&usg=AFQjCNHuHiS2MR9TIpYtu7C8bvgzuqxgMQ&cad=rja
  # zu klaeren. entPhysicalIndex entspricht dem entPhysicalindex der ENTITY-MIB.
  # In der stehen alle moeglichen Powersupplies etc.
  # Was bedeutet aber dann entSensorMeasuredEntity? gibt's eh nicht in meinen
  # Beispiel-walks
  $self->{thresholds} = [];
  $self->{entSensorMeasuredEntity} ||= 'undef';
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s sensor %s%s is %s',
      $self->{entSensorType},
      $self->{entPhysicalIndex},
      exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.')' : '',
      $self->{entSensorStatus});
  if ($self->{entSensorStatus} eq "nonoperational") {
    $self->add_critical();
  } elsif ($self->{entSensorStatus} eq "unknown_10") {
    # these sensors do not exist according to cisco-tools
    return;
  } elsif ($self->{entSensorStatus} eq "unavailable") {
    return;
  }
  my $label = sprintf('sens_%s_%s', $self->{entSensorType}, $self->{entPhysicalIndex});
  my $warningx = ($self->get_thresholds(metric => $label))[0];
  my $criticalx = ($self->get_thresholds(metric => $label))[1];
  if (scalar(@{$self->{thresholds}} == 4)) {
    # sowos gits aa.
    # an entSensorType: voltsAC mied 3249milli, der wou 4 thresholds hod.
    # owa: entSensorThresholdEvaluation: unknown_0,
    # entSensorThresholdSeverity: other
    # entSensorThresholdValue: 3630, entSensorThresholdRelation: lessThan
    # und de andern: entSensorThresholdValue: 3465, 2970, 3135
    # wos wuellsd ejtz do mocha? i dou jednfalls nix. es kinnts me.
  }
  if (scalar(@{$self->{thresholds}} == 2)) {
    # reparaturlauf
    foreach my $idx (0..1) {
      my $otheridx = $idx == 0 ? 1 : 0;
      if (! defined @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} &&   
          @{$self->{thresholds}}[$otheridx]->{entSensorThresholdSeverity} eq "minor") {
        @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} = "major";
      } elsif (! defined @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} &&   
          @{$self->{thresholds}}[$otheridx]->{entSensorThresholdSeverity} eq "minor") {
        @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} = "minor";
      }
    }
    my $warning = (map { $_->{entSensorThresholdValue} } 
        grep { $_->{entSensorThresholdSeverity} eq "minor" }
        @{$self->{thresholds}})[0];
    my $critical = (map { $_->{entSensorThresholdValue} } 
        grep { $_->{entSensorThresholdSeverity} eq "major" }
        @{$self->{thresholds}})[0];
    $self->set_thresholds(
        metric => $label,
        warning => $warning, critical => $critical
    );
    if ((defined($criticalx) && 
        $self->check_thresholds(metric => $label, value => $self->{entSensorValue}) == CRITICAL) ||
        (! defined($criticalx) && 
            grep { $_->{entSensorThresholdEvaluation} eq "true" } 
            grep { $_->{entSensorThresholdSeverity} eq "major" } @{$self->{thresholds}})) {
      # eigener schwellwert hat vorrang
      $self->add_critical(sprintf "%s sensor %s threshold evaluation is true (value: %s, major threshold: %s)", 
          $self->{entSensorType},
          $self->{entPhysicalIndex},
          $self->{entSensorValue},
          defined($criticalx) ? $criticalx : $critical
      );
    } elsif ((defined($warningx) && 
        $self->check_thresholds(metric => $label, value => $self->{entSensorValue}) == WARNING) ||
        (! defined($warningx) && 
            grep { $_->{entSensorThresholdEvaluation} eq "true" } 
            grep { $_->{entSensorThresholdSeverity} eq "minor" } @{$self->{thresholds}})) {
      $self->add_warning(sprintf "%s sensor %s threshold evaluation is true (value: %s, minor threshold: %s)", 
          $self->{entSensorType},
          $self->{entPhysicalIndex},
          $self->{entSensorValue},
          defined($warningx) ? $warningx : $warning
      );
    }
    $self->add_perfdata(
        label => $label,
        value => $self->{entSensorValue},
        warning => defined($warningx) ? $warningx : $warning,
        critical => defined($criticalx) ? $criticalx : $critical,
    );
  } elsif (defined $self->{entSensorValue}) {
    if ((defined($criticalx) && 
        $self->check_thresholds(metric => $label, value => $self->{entSensorValue}) == CRITICAL) ||
       (defined($warningx) && 
        $self->check_thresholds(metric => $label, value => $self->{entSensorValue}) == WARNING) ||
       ($self->{entSensorThresholdEvaluation} && $self->{entSensorThresholdEvaluation} eq "true")) {
    }
    if (defined($criticalx) &&
        $self->check_thresholds(metric => $label, value => $self->{entSensorValue}) == CRITICAL) {
      $self->add_critical(sprintf "%s sensor %s threshold evaluation is true (value: %s)",
          $self->{entSensorType},
          $self->{entPhysicalIndex},
          $self->{entSensorValue}
      );
      $self->add_perfdata(
          label => $label,
          value => $self->{entSensorValue},
          critical => $criticalx,
          warning => $warningx,
      );
    } elsif (defined($warningx) &&
        $self->check_thresholds(metric => $label, value => $self->{entSensorValue}) == WARNING) {
      $self->add_warning(sprintf "%s sensor %s threshold evaluation is true (value: %s)",
          $self->{entSensorType},
          $self->{entPhysicalIndex},
          $self->{entSensorValue}
      );
      $self->add_perfdata(
          label => $label,
          value => $self->{entSensorValue},
          critical => $criticalx,
          warning => $warningx,
      );
    } elsif ($self->{entSensorThresholdEvaluation} && $self->{entSensorThresholdEvaluation} eq "true") {
      $self->add_warning(sprintf "%s sensor %s threshold evaluation is true (value: %s)",
          $self->{entSensorType},
          $self->{entPhysicalIndex},
          $self->{entSensorValue}
      );
      $self->add_perfdata(
          label => $label,
          value => $self->{entSensorValue},
          warning => $self->{ciscoEnvMonSensorThreshold},
      );
    } else {
      $self->add_perfdata(
          label => $label,
          value => $self->{entSensorValue},
      );
    }
  } elsif (scalar(grep { $_->{entSensorThresholdEvaluation} eq "true" }
      @{$self->{thresholds}})) {
    $self->add_warning(sprintf "%s sensor %s threshold evaluation is true", 
        $self->{entSensorType},
        $self->{entPhysicalIndex});
  }
}


package Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::SensorThreshold;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{entPhysicalIndex} = $self->{indices}->[0];
  $self->{entSensorThresholdIndex} = $self->{indices}->[1];
}


package Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::PhysicalEntity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{entPhysicalIndex} = $self->{flat_indices};
}



__END__

nex5-rz2-04# sh env
Fan:
------------------------------------------------------
Fan             Model                Hw         Status
------------------------------------------------------
Chassis-1       N5K-C5010-FAN        --         ok
Chassis-2       N5K-C5010-FAN        --         ok
PS-1            N5K-PAC-550W         --         ok
PS-2            N5K-PAC-550W         --         ok
Temperature
-----------------------------------------------------------------
Module   Sensor     MajorThresh   MinorThres   CurTemp     Status
                    (Celsius)     (Celsius)    (Celsius)
-----------------------------------------------------------------
1        Outlet-1   60            50           45          ok
1        Outlet-2   60            50           46          ok
1        Intake-1   60            50           33          ok
1        Intake-2   60            50           34          ok
1        Intake-3   50            40           34          ok
1        Intake-4   50            40           34          ok
1        PS-1       60            50           33          ok
1        PS-2       60            50           31          ok
2        Outlet-1   60            50           38          ok


nex5-rz2-04# sh env fex all


Temperature Fex 100:
-----------------------------------------------------------------
Module   Sensor     MajorThresh   MinorThres   CurTemp     Status
                    (Celsius)     (Celsius)    (Celsius)
-----------------------------------------------------------------
1        Outlet-1   57            45           45          ok
1        Die-1      95            85           58          ok


Fan Fex: 100:
------------------------------------------------------
Fan             Model                Hw         Status
------------------------------------------------------
Chassis         N2K-C2248-FAN        --         ok
PS-1            N2200-PAC-400W       --         ok
PS-2            N2200-PAC-400W       --         ok


Power Supply Fex 100:
---------------------------------------------------------------------------
Voltage: 12 Volts
-----------------------------------------------------
PS  Model                Power       Power     Status
                         (Watts)     (Amp)
-----------------------------------------------------
1   N2200-PAC-400W        396.00     33.00     ok
2   N2200-PAC-400W        396.00     33.00     ok


Mod Model                Power     Power       Power     Power       Status
                         Requested Requested   Allocated Allocated
                         (Watts)   (Amp)       (Watts)   (Amp)
--- -------------------  -------   ----------  --------- ----------  ----------
1    N2K-C2248TP-1GE     85.20     7.10        85.20     7.10        powered-up


Power Usage Summary:
--------------------
Power Supply redundancy mode:                 redundant

Total Power Capacity                              792.00 W

Power reserved for Supervisor(s)                   85.20 W
Power currently used by Modules                     0.00 W

                                                -------------
Total Power Available                             706.80 W
                                                -------------


Temperature Fex 101:
-----------------------------------------------------------------
Module   Sensor     MajorThresh   MinorThres   CurTemp     Status
                    (Celsius)     (Celsius)    (Celsius)
-----------------------------------------------------------------
1        Outlet-1   57            45           42          ok
1        Die-1      95            85           53          ok


Fan Fex: 101:
------------------------------------------------------
Fan             Model                Hw         Status
------------------------------------------------------
Chassis         N2K-C2248-FAN        --         ok
PS-1            N2200-PAC-400W       --         ok
PS-2            N2200-PAC-400W       --         ok


Power Supply Fex 101:
---------------------------------------------------------------------------
Voltage: 12 Volts
-----------------------------------------------------
PS  Model                Power       Power     Status
                         (Watts)     (Amp)
-----------------------------------------------------
1   N2200-PAC-400W        396.00     33.00     ok
2   N2200-PAC-400W        396.00     33.00     ok


Mod Model                Power     Power       Power     Power       Status
                         Requested Requested   Allocated Allocated
                         (Watts)   (Amp)       (Watts)   (Amp)
--- -------------------  -------   ----------  --------- ----------  ----------
1    N2K-C2248TP-1GE     94.80     7.90        94.80     7.90        powered-up


Power Usage Summary:
--------------------
Power Supply redundancy mode:                 redundant

Total Power Capacity                              792.00 W

Power reserved for Supervisor(s)                   94.80 W
Power currently used by Modules                     0.00 W

                                                -------------
Total Power Available                             697.20 W
                                                -------------


OK - environmental hardware working fine, environmental hardware working fine
checking sensors
celsius sensor 100021590 (Fex-100 Module-1 Outlet-1) is ok
celsius sensor 100021591 (Fex-100 Module-1 Outlet-2) is unknown_10
celsius sensor 100021592 (Fex-100 Module-1 Inlet-1) is unknown_10
celsius sensor 101021590 (Fex-101 Module-1 Outlet-1) is ok
celsius sensor 101021591 (Fex-101 Module-1 Outlet-2) is unknown_10
celsius sensor 101021592 (Fex-101 Module-1 Inlet-1) is unknown_10
celsius sensor 21590 (Module-1, Outlet-1) is ok
celsius sensor 21591 (Module-1, Outlet-2) is ok
celsius sensor 21592 (Module-1, Intake-1) is ok
celsius sensor 21593 (Module-1, Intake-2) is ok
celsius sensor 21594 (Module-1, Intake-3) is ok
celsius sensor 21595 (Module-1, Intake-4) is ok
celsius sensor 21596 (PowerSupply-1 Sensor-1) is ok
celsius sensor 21597 (PowerSupply-2 Sensor-1) is ok
celsius sensor 21602 (Module-2, Outlet-1) is ok
checking fans
fan/tray 100000534 (Fex-100 FanModule-1 ) status is up
fan/tray 100000539 (Fex-100 PowerSupply-1 Fan-1 ) status is up
fan/tray 100000540 (Fex-100 PowerSupply-2 Fan-1 ) status is up
fan/tray 101000534 (Fex-101 FanModule-1 ) status is up
fan/tray 101000539 (Fex-101 PowerSupply-1 Fan-1 ) status is up
fan/tray 101000540 (Fex-101 PowerSupply-2 Fan-1 ) status is up
fan/tray 534 (FanModule-1 ) status is up
fan/tray 535 (FanModule-2 ) status is up
fan/tray 536 (PowerSupply-1 Fan-1 ) status is up
fan/tray 537 (PowerSupply-1 Fan-2 ) status is up
fan/tray 538 (PowerSupply-2 Fan-1 ) status is up
fan/tray 539 (PowerSupply-2 Fan-2 ) status is up | 'sens_celsius_100021590'=44 'sens_celsius_101021590'=41 'sens_celsius_21590'=44 'sens_celsius_21591'=46 'sens_celsius_21592'=33 'sens_celsius_21593'=34 'sens_celsius_21594'=34 'sens_celsius_21595'=33 'sens_celsius_21596'=33 'sens_celsius_21597'=31 'sens_celsius_21602'=38

