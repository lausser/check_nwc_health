package CheckNwcHealth::Cisco::NXOS::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

{
  our $cpmCPUTotalIndex = 0;
}

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-PROCESS-MIB', [
      ['cpus', 'cpmCPUTotalTable', 'CheckNwcHealth::Cisco::NXOS::Component::CpuSubsystem::Cpu' ],
  ]);
  if (scalar(@{$self->{cpus}}) == 0) {
    # maybe too old. i fake a cpu. be careful. this is a really bad hack
    my $response = $self->get_request(
        -varbindlist => [
            $CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1},
            $CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy5},
            $CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{busyPer},
        ]
    );
    if (exists $response->{$CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1}}) {
      push(@{$self->{cpus}},
          CheckNwcHealth::Cisco::NXOS::Component::CpuSubsystem::Cpu->new(
              cpmCPUTotalPhysicalIndex => 0, #fake
              cpmCPUTotalIndex => 0, #fake
              cpmCPUTotal5sec => 0, #fake
              cpmCPUTotal5secRev => 0, #fake
              cpmCPUTotal1min => $response->{$CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1}},
              cpmCPUTotal1minRev => $response->{$CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy1}},
              cpmCPUTotal5min => $response->{$CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy5}},
              cpmCPUTotal5minRev => $response->{$CheckNwcHealth::Device::mibs_and_oids->{'OLD-CISCO-CPU-MIB'}->{avgBusy5}},
              cpmCPUMonInterval => 0, #fake
              cpmCPUTotalMonIntervalValue => 0, #fake
              cpmCPUInterruptMonIntervalValue => 0, #fake
      ));
    }
  }
}

package CheckNwcHealth::Cisco::NXOS::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cpmCPUTotalIndex} = exists $self->{cpmCPUTotalIndex} ?
      $self->{cpmCPUTotalIndex} :
      $CheckNwcHealth::Cisco::NXOS::Component::CpuSubsystem::cpmCPUTotalIndex++;
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
    $self->{name} = $self->{entPhysicalName};
    $self->{name} .= ' '.$self->{entPhysicalAssetID} if $self->{entPhysicalAssetID};
    $self->{label} = $self->{entPhysicalName};
    $self->{label} .= ' '.$self->{entPhysicalAssetID} if $self->{entPhysicalAssetID};
  } else {
    $self->{name} = $self->{cpmCPUTotalIndex};
    $self->{label} = $self->{cpmCPUTotalIndex};
  }
  return $self;
}

sub check {
  my ($self) = @_;
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


