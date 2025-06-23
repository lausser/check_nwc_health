package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->require_mib("MIB-2-MIB");
  $self->require_mib("ENTITY-STATE-MIB");
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ENTITY-STATE-MIB'}->{entStateLastChangedDefinition} = 'MIB-2-MIB::DateAndTime';
  $self->get_snmp_tables_cached('ENTITY-MIB', [
    ['entities', 'entPhysicalTable',
      'CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity',
      undef,
      ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName', 'entPhysicalContainedIn']
    ],
  ]);
  $self->get_snmp_tables('ENTITY-SENSOR-MIB', [
    ['sensorvalues', 'entPhySensorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  $self->get_snmp_tables('ENTITY-STATE-MIB', [
    ['sensorstates', 'entStateTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  #printf "i have %d entities\n", scalar(@{$self->{entities}});
  #printf "i have %d sensorvalues\n", scalar(@{$self->{sensorvalues}});
  #printf "i have %d sensorstates\n", scalar(@{$self->{sensorstates}});
  $self->merge_tables("entities", "sensorvalues", "sensorstates");
  # Nach dem merge gibt es tatsaechlich noch sensorvalues, die nicht
  # mit entities korrespondieren (gleiche Index haben). In den Beispielen
  # waren das aber irgendwelche schrottigen Dinger mit leeren Attributen.
  my @sensorlist = ();
  foreach my $entity (@{$self->{entities}}) {
    $entity->rebless();
    $entity->{sensors} = [] if $entity->{entPhysicalClass} ne "sensor";
    push(@sensorlist, $entity) if $entity->{entPhysicalClass} eq "sensor" and not $entity->{invalid};
  }
  # und dann gibt es ggf. auch noch sensors, die nichts taugen.
  @{$self->{entities}} = grep {
    not exists $_->{invalid} or $_->{invalid};
  } @{$self->{entities}};
  foreach my $entity (@{$self->{entities}}) {
    next if $entity->{entPhysicalClass} eq "sensor";
    foreach my $sensor (@sensorlist) {
      if ($sensor->{entPhysicalContainedIn} eq $entity->{flat_indices}) {
        # assign the sensors to the upper layer items like fans
        push(@{$entity->{sensors}}, $sensor);
      }
    }
  }
  # @assigned_sensors are standalone-sensors, not assigned to fans, ps,..
  # i think such sensors do not exist, so we delete all sensors for now.
  @{$self->{entities}} = grep {
    not $_->{entPhysicalClass} eq "sensor";
  } @{$self->{entities}};
  my $embeddedsensors = 0;
  @{$self->{entities}} = map {
    $embeddedsensors += scalar(@{$_->{sensors}});
    $_;
  } @{$self->{entities}};
  #printf "i have %d entities (non-sensor)\n", scalar(@{$self->{entities}});
  #printf "i have %d sensorvalues\n", scalar(@{$self->{sensorvalues}});
  #printf "i have %d sensorstates\n", scalar(@{$self->{sensorstates}});
  #printf "i have %d embeddedsensors\n", $embeddedsensors;
#$self->dump();
}

sub check {
  my ($self) = @_;
  $self->{powerSupplyList} = [map {
      $_->{entPhysicalDescr};
  } grep {
      $_->{entPhysicalClass} eq 'powerSupply';
  } @{$self->{entities}}];
  #
  # Check if we lost a power supply. (pulling ps -> entry in snmp disappears)
  #
  $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
  $self->valdiff({name => 'powersupplies', lastarray => 1},
      qw(powerSupplyList));
  if (scalar(@{$self->{delta_found_powerSupplyList}}) > 0) {
    $self->add_ok(sprintf '%d new power supply (%s)',
        scalar(@{$self->{delta_found_powerSupplyList}}),
        join(", ", @{$self->{delta_found_powerSupplyList}}));
  }
  if (scalar(@{$self->{delta_lost_powerSupplyList}}) > 0) {
    $self->add_critical(sprintf '%d power supply missing (%s)',
        scalar(@{$self->{delta_lost_powerSupplyList}}),
        join(", ", @{$self->{delta_lost_powerSupplyList}}));
  }
  delete $self->{powerSupplyList};
  delete $self->{delta_found_powerSupplyList};
  delete $self->{delta_lost_powerSupplyList};
  $self->SUPER::check();
}

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


sub rebless {
  my ($self) = @_;
  bless $self,
      'CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::'.ucfirst($self->{entPhysicalClass});
  if ($self->can("finish")) {
    #printf "%s can finish\n", ref($self);
    $self->finish();
  }
}

sub check_state {
  my ($self) = @_;
  # An ifAdminStatus of 'up' is equivalent to setting the entStateAdmin
  # object to 'unlocked'.  An ifAdminStatus of 'down' is equivalent to
  # setting the entStateAdmin object to either 'locked' or
  # 'shuttingDown', depending on a system's interpretation of 'down'.
  $self->add_info(sprintf "%s is %s (admin %s, oper %s)",
      $self->{entPhysicalDescr}, $self->{entStateUsage},
      $self->{entStateAdmin}, $self->{entStateOper});
  if ($self->{entStateAdmin} eq "unlocked") {
    if ($self->{entStateOper} eq "enabled") {
      if ($self->{entStateUsage} eq "idle") {
        $self->add_ok();
      } elsif ($self->{entStateUsage} eq "active") {
        $self->add_ok();
      } elsif ($self->{entStateUsage} eq "busy") {
        $self->add_warning();
      } else {
        $self->add_unknown();
      }
    } elsif ($self->{entStateOper} eq "disabled") {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
  } elsif ($self->{entStateAdmin} eq "locked") {
    $self->add_ok(); # admin disabled, ignore
  } elsif (defined $self->{entPhySensorOperStatus} and $self->{entStateAdmin} eq "unknown" and $self->{entStateOper} eq "unknown" and $self->{entPhySensorOperStatus} eq "unavailable") {
    # Fans und Powersupplies haben kein entPhySensor*-Gedoens
    # The value 'unavailable(2)' indicates that the agent presently cannot obtain the sensor value. The value 'nonoperational(3)' indicates that the agent believes the sensor is broken. The sensor could have a hard failure (disconnected wire), ...
    # Ich will meine Ruhe, also unavailable=ok. Sonst waers ja nonoperational
    $self->add_ok();
  } elsif ($self->{entStateOper} ne "enabled" and $self->{entStateStandby} eq "providingService" and exists $self->{entPhySensorValue} and $self->{entPhySensorValue}) {
    $self->add_critical();
  } elsif ($self->{entStateAlarm}) {
    $self->add_critical(sprintf "alarm in %s", $self->{entPhysicalDescr});
  } else {
    $self->add_ok(); # admin disabled, ignore
  }
}

sub check {
  my ($self) = @_;
  $self->check_state() if exists $self->{entStateOper};
  foreach my $sensor (@{$self->{sensors}}) {
    $sensor->check();
  }
}


package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Chassis; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Container; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::PowerSupply; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 
sub check_state {
  my ($self) = @_;
  $self->SUPER::check_state();
  if ($self->{entStateAdmin} eq "locked" &&
      $self->{entStateOper} eq "disabled" &&
      $self->{entStateStandby} eq "providingService" &&
      $self->{entStateUsage} eq "active") {
    # pull the power cable -> entStateAdmin: locked, entStateOper: disabled,
    #     entStateStandby: providingService, entStateUsage: active
    $self->add_warning_mitigation(sprintf "%s is down (pulled cable?)", $self->{entPhysicalDescr});
  } elsif ($self->{entStateOper} eq "unknown" and $self->{entStateAdmin} eq "unknown" and $self->{entStateStandby} eq "providingService") {
    # pull the power supply, put it back.
    $self->add_critical_mitigation(sprintf "%s is in an unknown state", $self->{entPhysicalDescr});
  }
}

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Fan; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Sensor; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 
sub finish {
  my ($self) = @_;
  if (! defined $self->{entPhySensorValue}) {
    # Entity mit entPhysicalClass sensor, die nicht mit einem Eintrag aus der
    # entPhySensorTable gemergt wurde. Z.b. Tachometersensor eines Fans
    # den es gar nicht gibt.
    $self->{invalid} = 1;
    return;
  } elsif ($self->{entPhySensorValue} == -1000000000 ||
        $self->{entPhySensorValue} == 1000000000) {
    # The value -1000000000 indicates an underflow error.
    # The value +1000000000 indicates an overflow error.
    # <nachaeff>kann man das nicht clientseitig abfangen?</nachaeff>
    $self->{invalid} = 1;
    return;
  } elsif ($self->{entPhySensorOperStatus} and $self->{entPhySensorOperStatus} eq "unavailable") {
    # DOM TX Bias Sensor for Eth1/33/4
    $self->{invalid} = 1;
    return;
  }
  foreach (qw(entPhySensorValue)) {
    delete $self->{$_} if defined $self->{$_} && $_ ne 'entPhySensorValue' &&
        ($self->{$_} == -1000000000 || $self->{$_} == 1000000000);
    if ($self->{entPhySensorPrecision} && $self->{$_}) {
      $self->{$_} /= 10 ** $self->{entPhySensorPrecision};
    }
  }
}

sub check {
  my ($self) = @_;
  $self->check_state() if exists $self->{entStateAdmin};
  if ($self->{entPhySensorOperStatus} and $self->{entPhySensorOperStatus} eq "nonoperational") {
    $self->add_warning(sprintf "%s has a problem", $self->{entPhysicalDescr});
  }
  my ($warn, $crit) = (undef, undef);
  my $metric = $self->{entPhySensorUnitsDisplay} ?
      $self->{entPhysicalDescr}.'_'.$self->{entPhySensorUnitsDisplay} :
      $self->{entPhysicalDescr};
  if ($metric =~ /temp/i or $self->{entPhySensorType} eq "celsius") {
    $metric =~ s/[Tt]emperature//;
    $metric =~ s/(.*)_temp\(([0-9a-zA-Zx]+)\)/$1_$2/g;
    $metric =~ s/^/temp /;
    $metric =~ s/_temp$//;
  } elsif ($metric =~ /tacho/i) {
    $metric =~ s/[Tt]achometers*//;
    $metric =~ s/^/rpm /;
  }
  $metric =~ s/\s+/_/g;
  $self->set_thresholds(metric => $metric,
      warning => $warn, critical => $crit);
  my $level = $self->check_thresholds(metric => $metric,
      value => $self->{entPhySensorValue});
  if ($level) {
    $self->add_message($level, sprintf "%s has a value of %s",
        $self->{entPhysicalDescr}, $self->{entPhySensorValue});
  }
  $self->add_perfdata(
      label => $metric,
      value => $self->{entPhySensorValue},
      #warning => $warn, critical => $crit,
  #) if $self->{entPhysicalDescr} !~ /DOM (.X) (Power|Bias|Voltage) Sensor for Eth/;
  ) if $self->{entPhysicalDescr} !~ /DOM .*(Power|Bias|Voltage) Sensor for Eth/;
}

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Module; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Port; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Stack; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Cpu; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;

#------

__END__


package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Chassis; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;
 

package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Backplane; 
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;


package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Module;
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;


package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Port;
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;


package CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem::Entity);
use strict;


__END__
Stecker gezogen
[POWERSUPPLY_100721000]
entPhysicalClass: powerSupply
entPhysicalDescr: PowerSupply2
entPhysicalName:
entStateAdmin: unknown
entStateLastChanged:
entStateOper: unknown
entStateStandby: providingService <-kein failover, der das hier sichert
entStateUsage: active
So war das bei Arista implementiert, also incl Pruefung, ob ein PS verschwunden ist

