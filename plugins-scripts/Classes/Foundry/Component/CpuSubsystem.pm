package Classes::Foundry::Component::CpuSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['cpus', 'snAgentCpuUtilTable', 'Classes::Foundry::Component::CpuSubsystem::Cpu'],
  ]);
  $self->get_snmp_objects('FOUNDRY-SN-AGENT-MIB', (qw(
      snAgGblCpuUtil1SecAvg snAgGblCpuUtil5SecAvg snAgGblCpuUtil1MinAvg)));
}

sub check {
  my $self = shift;
  if (scalar (@{$self->{cpus}}) == 0) {
    $self->overall_check();
  } else {
    # snAgentCpuUtilInterval = 1, 5, 60, 300
    # --lookback can be one of these values, default is 300 (1,5 is a stupid choice)
    $self->opts->override_opt('lookback', 300) if ! $self->opts->lookback;
    foreach (grep { $_->{snAgentCpuUtilInterval} eq $self->opts->lookback} @{$self->{cpus}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  $self->overall_dump();
  foreach (@{$self->{cpus}}) {
    $_->dump();
  }
}

sub overall_check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{snAgGblCpuUtil1MinAvg});
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds(
      $self->{snAgGblCpuUtil1MinAvg}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{snAgGblCpuUtil1MinAvg},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub overall_dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(snAgGblCpuUtil1SecAvg snAgGblCpuUtil5SecAvg
      snAgGblCpuUtil1MinAvg)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}

sub unix_init {
  my $self = shift;
  my %params = @_;
  my $type = 0;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['loads', 'laTable', 'Classes::Foundry::Component::CpuSubsystem::Load'],
  ]);
}

sub unix_check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking loads');
  foreach (@{$self->{loads}}) {
    $_->check();
  }
}

sub unix_dump {
  my $self = shift;
  foreach (@{$self->{loads}}) {
    $_->dump();
  }
}


package Classes::Foundry::Component::CpuSubsystem::Cpu;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  # newer mibs have snAgentCpuUtilPercent and snAgentCpuUtil100thPercent
  # snAgentCpuUtilValue is deprecated
  $self->{snAgentCpuUtilValue} = $self->{snAgentCpuUtil100thPercent} / 100
      if defined $self->{snAgentCpuUtil100thPercent};
  # if it is an old mib, watch out. snAgentCpuUtilValue is 100th of a percent
  # but it seems that sometimes in reality it is percent
  $self->{snAgentCpuUtilValue} = $self->{snAgentCpuUtilValue} / 100
      if $self->{snAgentCpuUtilValue} > 100;
  $self->add_info(sprintf 'cpu %s usage is %.2f', $self->{snAgentCpuUtilSlotNum}, $self->{snAgentCpuUtilValue});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{snAgentCpuUtilValue}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{snAgentCpuUtilSlotNum},
      value => $self->{snAgentCpuUtilValue},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}


package Classes::Foundry::Component::CpuSubsystem::Load;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info(sprintf '%s is %.2f', lc $self->{laNames}, $self->{laLoadFloat});
  $self->set_thresholds(warning => $self->{laConfig},
      critical => $self->{laConfig});
  $self->add_message($self->check_thresholds($self->{laLoadFloat}));
  $self->add_perfdata(
      label => lc $self->{laNames},
      value => $self->{laLoadFloat},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

