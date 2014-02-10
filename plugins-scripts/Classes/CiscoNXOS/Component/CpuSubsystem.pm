package Classes::CiscoNXOS::Component::CpuSubsystem;
our @ISA = qw(Classes::CiscoNXOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    cpus => [],
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
  my $type = 0;
  foreach ($self->get_snmp_table_objects(
      'CISCO-PROCESS-MIB', 'cpmCPUTotalTable')) {
    $_->{cpmCPUTotalIndex} ||= $type++;
    push(@{$self->{cpus}},
        Classes::CiscoNXOS::Component::CpuSubsystem::Cpu->new(%{$_}));
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
          Classes::CiscoNXOS::Component::CpuSubsystem::Cpu->new(
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
  my $errorfound = 0;
  $self->add_info('checking cpus');
  $self->blacklist('ff', '');
  if (scalar (@{$self->{cpus}}) == 0) {
  } else {
    foreach (@{$self->{cpus}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{cpus}}) {
    $_->dump();
  }
}


package Classes::CiscoNXOS::Component::CpuSubsystem::Cpu;
our @ISA = qw(Classes::CiscoNXOS::Component::CpuSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $param (qw(cpmCPUTotalIndex cpmCPUTotalPhysicalIndex
      cpmCPUTotal5sec cpmCPUTotal1min cpmCPUTotal5min
      cpmCPUTotal5secRev cpmCPUTotal1minRev cpmCPUTotal5minRev
      cpmCPUMonInterval cpmCPUTotalMonIntervalValue
      cpmCPUInterruptMonIntervalValue)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  $self->{usage} = $params{cpmCPUTotal5minRev};
  if ($self->{cpmCPUTotalPhysicalIndex}) {
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

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{cpmCPUTotalPhysicalIndex};
  foreach (qw(cpmCPUTotalIndex cpmCPUTotalPhysicalIndex cpmCPUTotal5sec cpmCPUTotal1min cpmCPUTotal5min cpmCPUTotal5secRev cpmCPUTotal1minRev cpmCPUTotal5minRev cpmCPUMonInterval cpmCPUTotalMonIntervalValue cpmCPUInterruptMonIntervalValue)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

