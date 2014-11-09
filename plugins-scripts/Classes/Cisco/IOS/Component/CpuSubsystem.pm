package Classes::Cisco::IOS::Component::CpuSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;
use constant PHYS_NAME => 1;
use constant PHYS_ASSET => 2;
use constant PHYS_DESCR => 4;

{
  our $cpmCPUTotalIndex = 0;
  our $uniquify = PHYS_NAME;
}

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-PROCESS-MIB', [
      ['cpus', 'cpmCPUTotalTable', 'Classes::Cisco::IOS::Component::CpuSubsystem::Cpu' ],
  ]);
  if (scalar(@{$self->{cpus}}) == 0) {
    # maybe too old. i fake a cpu. be careful. this is a really bad hack
    my $response = $self->get_request(
        -varbindlist => [
            $Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1},
            $Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy5},
            $Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{busyPer},
        ]
    );
    if (exists $response->{$Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1}}) {
      push(@{$self->{cpus}},
          Classes::Cisco::IOS::Component::CpuSubsystem::Cpu->new(
              cpmCPUTotalPhysicalIndex => 0, #fake
              cpmCPUTotalIndex => 0, #fake
              cpmCPUTotal5sec => 0, #fake
              cpmCPUTotal5secRev => 0, #fake
              cpmCPUTotal1min => $response->{$Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1}},
              cpmCPUTotal1minRev => $response->{$Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1}},
              cpmCPUTotal5min => $response->{$Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy5}},
              cpmCPUTotal5minRev => $response->{$Classes::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy5}},
              cpmCPUMonInterval => 0, #fake
              cpmCPUTotalMonIntervalValue => 0, #fake
              cpmCPUInterruptMonIntervalValue => 0, #fake
      ));
    }
  }
  foreach my $cpu (@{$self->{cpus}}) {
printf "%-20s%s\n", $cpu->{name}, $cpu->{label};
  }
$Classes::Cisco::IOS::Component::CpuSubsystem::uniquify |= PHYS_ASSET;
  foreach my $cpu (@{$self->{cpus}}) {
printf "%-20s%s\n", $cpu->{name}, $cpu->{label};
  }
$Classes::Cisco::IOS::Component::CpuSubsystem::uniquify |= PHYS_DESCR;
  foreach my $cpu (@{$self->{cpus}}) {
printf "%-20s%s\n", $cpu->{name}, $cpu->{label};
  }
die;
}

package Classes::Cisco::IOS::Component::CpuSubsystem::Cpu;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{cpmCPUTotalIndex} = exists $self->{cpmCPUTotalIndex} ?
      $self->{cpmCPUTotalIndex} :
      $Classes::Cisco::IOS::Component::CpuSubsystem::cpmCPUTotalIndex++;
  $self->{cpmCPUTotalPhysicalIndex} = exists $self->{cpmCPUTotalPhysicalIndex} ?
      $self->{cpmCPUTotalPhysicalIndex} : 0;
  if (exists $self->{cpmCPUTotal5minRev}) {
    $self->{usage} = $self->{cpmCPUTotal5minRev};
  } else {
    $self->{usage} = $self->{cpmCPUTotal5min};
  }
  $self->protect_value($self->{cpmCPUTotalIndex}.$self->{cpmCPUTotalPhysicalIndex}, 'usage', 'percent');
  if ($self->{cpmCPUTotalPhysicalIndex}) {
    $self->{entPhysicalName} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalName', $self->{cpmCPUTotalPhysicalIndex});
    # wichtig fuer gestacktes zeugs, bei dem entPhysicalName doppelt und mehr vorkommen kann
    # This object is a user-assigned asset tracking identifier for the physical entity
    # as specified by a network manager, and provides non-volatile storage of this
    # information. On the first instantiation of an physical entity, the value of
    # entPhysicalAssetID associated with that entity is set to the zero-length string.
    # ...
    # If write access is implemented for an instance of entPhysicalAssetID, and a value
    # is written into the instance, the agent must retain the supplied value in the
    # entPhysicalAssetID instance associated with the same physical entity for as long
    # as that entity remains instantiated. This includes instantiations across all
    # re-initializations/reboots of the network management system, including those
    # which result in a change of the physical entity's entPhysicalIndex value.
    $self->{entPhysicalAssetID} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalAssetID', $self->{cpmCPUTotalPhysicalIndex});
    $self->{entPhysicalDescr} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalDescr', $self->{cpmCPUTotalPhysicalIndex});
    $self->unique_name();
  } else {
    $self->{name} = $self->{cpmCPUTotalIndex};
    $self->{label} = $self->{cpmCPUTotalIndex};
  }
  return $self;
}

sub unique_name {
  my $self = shift;
    $self->{name} = ();
    $self->{label} = ();
    if ($Classes::Cisco::IOS::Component::CpuSubsystem::uniquify |
        Classes::Cisco::IOS::Component::CpuSubsystem::PHYS_NAME) {
printf "PHYS_NAME\n";
      push(@{$self->{name}}, $self->{entPhysicalName});
    }
    if ($Classes::Cisco::IOS::Component::CpuSubsystem::uniquify |
        Classes::Cisco::IOS::Component::CpuSubsystem::PHYS_ASSET) {
printf "PHYS_ASSET\n";
      push(@{$self->{name}}, $self->{entPhysicalAssetID});
    }
    if ($Classes::Cisco::IOS::Component::CpuSubsystem::uniquify |
        Classes::Cisco::IOS::Component::CpuSubsystem::PHYS_DESCR) {
printf "PHYS_DESCR\n";
      push(@{$self->{name}}, $self->{entPhysicalDescr});
    }
    $self->{name} = join(' ', @{$self->{name}});
    $self->{label} = $self->{name};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cpu %s usage (5 min avg.) is %.2f%%',
      $self->{name}, $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{label}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

