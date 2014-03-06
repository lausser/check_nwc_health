package Classes::CiscoIOS::Component::CpuSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my $self = shift;
  my $idx = 0;
  $self->get_snmp_tables('CISCO-PROCESS-MIB', [
      ['cpus', 'cpmCPUTotalTable', 'Classes::CiscoIOS::Component::CpuSubsystem::Cpu'],
  ]);
  foreach (@{$self->{cpus}}) {
    $_->{cpmCPUTotalIndex} ||= $idx++;
  }
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
          Classes::CiscoIOS::Component::CpuSubsystem::Cpu->new(
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

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('ff', '');
  foreach (@{$self->{cpus}}) {
    $_->check();
  }
}


package Classes::CiscoIOS::Component::CpuSubsystem::Cpu;
our @ISA = qw(GLPlugin::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my $self = shift;
  my %params = @_;
  if (exists $params{cpmCPUTotal5minRev}) {
    $self->{usage} = $params{cpmCPUTotal5minRev};
  } else {
    $self->{usage} = $params{cpmCPUTotal5min};
  }
  $self->protect_value(($self->{cpmCPUTotalIndex}||"").($self->{cpmCPUTotalPhysicalIndex}||""), 'usage', 'percent');
  if (defined $self->{cpmCPUTotalPhysicalIndex}) {
    my $entPhysicalName = '1.3.6.1.2.1.47.1.1.1.1.7';
    $self->{entPhysicalName} = $self->get_request(
        -varbindlist => [$entPhysicalName.'.'.$self->{cpmCPUTotalPhysicalIndex}]
    );
    $self->{entPhysicalName} = $self->{entPhysicalName}->{$entPhysicalName.'.'.$self->{cpmCPUTotalPhysicalIndex}};
  } else {
    $self->{entPhysicalName} = $self->{cpmCPUTotalIndex};
  }
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{cpmCPUTotalPhysicalIndex});
  my $info = sprintf 'cpu %s usage (5 min avg.) is %.2f%%',
      $self->{entPhysicalName}, $self->{usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}), $info);
  $self->add_perfdata(
      label => 'cpu_'.$self->{entPhysicalName}.'_usage',
      value => $self->{usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

