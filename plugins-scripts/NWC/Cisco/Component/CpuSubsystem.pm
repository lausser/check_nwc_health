package NWC::Cisco::Component::CpuSubsystem;
our @ISA = qw(NWC::Cisco);

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
      #'CISCO-PROCESS-MIB', 'cpmCPUTotalTable')) {
    $_->{cpmCPUTotalIndex} ||= $type++;
    push(@{$self->{cpus}},
        NWC::Cisco::Component::CpuSubsystem::Cpu->new(%{$_}));
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


package NWC::Cisco::Component::CpuSubsystem::Cpu;
our @ISA = qw(NWC::Cisco::Component::CpuSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    cpmCPUTotalIndex => $params{cpmCPUTotalIndex},
    cpmCPUTotalPhysicalIndex => $params{cpmCPUTotalPhysicalIndex},
    cpmCPUTotal5sec => $params{cpmCPUTotal5sec},
    cpmCPUTotal1min => $params{cpmCPUTotal1min},
    cpmCPUTotal5min => $params{cpmCPUTotal5min},
    cpmCPUTotal5secRev => $params{cpmCPUTotal5secRev},
    cpmCPUTotal1minRev => $params{cpmCPUTotal1minRev},
    cpmCPUTotal5minRev => $params{cpmCPUTotal5minRev},
    cpmCPUMonInterval => $params{cpmCPUMonInterval},
    cpmCPUTotalMonIntervalValue => $params{cpmCPUTotalMonIntervalValue},
    cpmCPUInterruptMonIntervalValue => $params{cpmCPUInterruptMonIntervalValue},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
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

