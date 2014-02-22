package Classes::F5::F5BIGIP::Component::CpuSubsystem;
our @ISA = qw(Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  if ($self->mode =~ /load/) {
    $self->overall_init();
  } else {
    $self->init();
  }
  return $self;
}

sub overall_init {
  my $self = shift;
  $self->{sysStatTmTotalCycles} = $self->get_snmp_object(
      'F5-BIGIP-SYSTEM-MIB', 'sysStatTmTotalCycles');
  $self->{sysStatTmIdleCycles} = $self->get_snmp_object(
      'F5-BIGIP-SYSTEM-MIB', 'sysStatTmIdleCycles');
  $self->{sysStatTmSleepCycles} = $self->get_snmp_object(
      'F5-BIGIP-SYSTEM-MIB', 'sysStatTmSleepCycles');
  $self->valdiff({name => 'cpu'}, qw(sysStatTmTotalCycles sysStatTmIdleCycles sysStatTmSleepCycles ));
  my $delta_used_cycles = $self->{delta_sysStatTmTotalCycles} -
     ($self->{delta_sysStatTmIdleCycles} + $self->{delta_sysStatTmSleepCycles});
  $self->{cpu_usage} =  $self->{delta_sysStatTmTotalCycles} ?
      (($delta_used_cycles / $self->{delta_sysStatTmTotalCycles}) * 100) : 0;
}

sub init {
  my $self = shift;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['cpus', 'sysCpuTable', 'Classes::F5::F5BIGIP::Component::CpuSubsystem::Cpu'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('cc', '');
  if ($self->mode =~ /load/) {
    my $info = sprintf 'tmm cpu usage is %.2f%%',
        $self->{cpu_usage};
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds($self->{cpu_usage}), $info);
    $self->add_perfdata(
        label => 'cpu_tmm_usage',
        value => $self->{cpu_usage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    return;
  }
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


package Classes::F5::F5BIGIP::Component::CpuSubsystem::Cpu;
our @ISA = qw(Classes::F5::F5BIGIP::Component::CpuSubsystem);
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
  foreach(qw(sysCpuIndex sysCpuTemperature sysCpuFanSpeed
      sysCpuName sysCpuSlot)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{sysCpuIndex});
  $self->add_info(sprintf 'cpu %d has %dC (%drpm)',
      $self->{sysCpuIndex},
      $self->{sysCpuTemperature},
      $self->{sysCpuFanSpeed});
  $self->add_perfdata(
      label => sprintf('temp_c%s', $self->{sysCpuIndex}),
      value => $self->{sysCpuTemperature},
      warning => undef,
      critical => undef,
  );
  $self->add_perfdata(
      label => sprintf('fan_c%s', $self->{sysCpuIndex}),
      value => $self->{sysCpuFanSpeed},
      warning => undef,
      critical => undef,
  );
}

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{sysCpuIndex};
  foreach(qw(sysCpuIndex sysCpuTemperature sysCpuFanSpeed
      sysCpuName sysCpuSlot)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

