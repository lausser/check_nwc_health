package NWC::Foundry::Component::CpuSubsystem;
our @ISA = qw(NWC::Foundry);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    loads => [],
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
  foreach ($self->get_snmp_table_objects(
      'FOUNDRY-SN-AGENT-MIB', 'snAgentCpuUtilTable')) {
    push(@{$self->{cpus}},
        NWC::Foundry::Component::CpuSubsystem::Cpu->new(%{$_}));
  }
  foreach (qw(snAgGblCpuUtil1SecAvg snAgGblCpuUtil5SecAvg
      snAgGblCpuUtil1MinAvg)) {
    $self->{$_} = $self->get_snmp_object('FOUNDRY-SN-AGENT-MIB', $_);
  }
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
  $self->blacklist('c', undef);
  my $info = sprintf 'cpu usage is %.2f%%', $self->{snAgGblCpuUtil1MinAvg};
  $self->add_info($info);
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds(
      $self->{snAgGblCpuUtil1MinAvg}), $info);
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
  foreach ($self->get_snmp_table_objects(
     'UCD-SNMP-MIB', 'laTable')) {
    push(@{$self->{loads}},
        NWC::Foundry::Component::CpuSubsystem::Load->new(%{$_}));
  }
}

sub unix_check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking loads');
  $self->blacklist('c', '');
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


package NWC::Foundry::Component::CpuSubsystem::Cpu;
our @ISA = qw(NWC::Foundry::Component::CpuSubsystem);

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
  foreach (qw(snAgentCpuUtilSlotNum snAgentCpuUtilCpuId 
      snAgentCpuUtilInterval snAgentCpuUtilValue
      snAgentCpuUtilPercent snAgentCpuUtil100thPercent)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  # newer mibs have snAgentCpuUtilPercent and snAgentCpuUtil100thPercent
  # snAgentCpuUtilValue is deprecated
  $self->{snAgentCpuUtilValue} = $self->{snAgentCpuUtil100thPercent} / 100
      if defined $self->{snAgentCpuUtil100thPercent};
  # if it is an old mib, watch out. snAgentCpuUtilValue is 100th of a percent
  # but it seems that sometimes in reality it is percent
  $self->{snAgentCpuUtilValue} = $self->{snAgentCpuUtilValue} / 100
      if $self->{snAgentCpuUtilValue} > 100;
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->blacklist('c', undef);
  my $info = sprintf 'cpu %s usage is %.2f', $self->{snAgentCpuUtilSlotNum}, $self->{snAgentCpuUtilValue};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{snAgentCpuUtilValue}), $info);
  $self->add_perfdata(
      label => 'cpu_'.$self->{snAgentCpuUtilSlotNum},
      value => $self->{snAgentCpuUtilValue},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{snAgentCpuUtilSlotNum};
  foreach (qw(snAgentCpuUtilSlotNum snAgentCpuUtilCpuId 
      snAgentCpuUtilInterval snAgentCpuUtilValue
      snAgentCpuUtilPercent snAgentCpuUtil100thPercent)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info} || "unchecked";
  printf "\n";
}


package NWC::Foundry::Component::CpuSubsystem::Load;
our @ISA = qw(NWC::Foundry::Component::CpuSubsystem);

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
  foreach my $param (qw(laIndex laNames laLoad laConfig laLoadFloat 
      laErrorFlag laErrMessage)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->blacklist('c', undef);
  my $info = sprintf '%s is %.2f', lc $self->{laNames}, $self->{laLoadFloat};
  $self->add_info($info);
  $self->set_thresholds(warning => $self->{laConfig},
      critical => $self->{laConfig});
  $self->add_message($self->check_thresholds($self->{laLoadFloat}), $info);
  $self->add_perfdata(
      label => lc $self->{laNames},
      value => $self->{laLoadFloat},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[LOAD_%s]\n", lc $self->{laNames};
  foreach (qw(laIndex laNames laLoad laConfig laLoadFloat 
      laErrorFlag laErrMessage)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

