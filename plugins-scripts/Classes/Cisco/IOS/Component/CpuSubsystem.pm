package Classes::Cisco::IOS::Component::CpuSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

{
  our $cpmCPUTotalIndex = 0;
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
    my $entPhysicalName = '1.3.6.1.2.1.47.1.1.1.1.7';
    $self->{entPhysicalName} = $self->get_request(
        -varbindlist => [$entPhysicalName.'.'.$self->{cpmCPUTotalPhysicalIndex}]
    );
    $self->{entPhysicalName} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalName', $self->{cpmCPUTotalPhysicalIndex});
  } else {
    $self->{entPhysicalName} = $self->{cpmCPUTotalIndex};
  }
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cpu %s usage (5 min avg.) is %.2f%%',
      $self->{entPhysicalName}, $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(value => $self->{usage},
      metric => 'cpu_'.$self->{entPhysicalName}.'_usage'));
  $self->add_perfdata(
      label => 'cpu_'.$self->{entPhysicalName}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

