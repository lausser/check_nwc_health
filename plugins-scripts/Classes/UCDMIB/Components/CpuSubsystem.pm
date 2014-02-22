package Classes::UCDMIB::Component::CpuSubsystem;
our @ISA = qw(Classes::UCDMIB);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  foreach (qw(ssCpuUser ssCpuSystem ssCpuIdle
      ssCpuRawUser ssCpuRawSystem ssCpuRawIdle ssCpuRawNice)) {
    $self->{$_} = $self->get_snmp_object('UCD-SNMP-MIB', $_, 0);
  }
  $self->valdiff({name => 'cpu'}, qw(ssCpuRawUser ssCpuRawSystem ssCpuRawIdle ssCpuRawNice));
  my $cpu_total = $self->{delta_ssCpuRawUser} + $self->{delta_ssCpuRawSystem} +
      $self->{delta_ssCpuRawIdle} + $self->{delta_ssCpuRawNice};
  if ($cpu_total == 0) {
    $self->{cpu_usage} = 0;
  } else {
    $self->{cpu_usage} = (100 - ($self->{delta_ssCpuRawIdle} / $cpu_total) * 100);
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('c', undef);
  my $info = sprintf 'cpu usage is %.2f%%', $self->{cpu_usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{cpu_usage}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(ssCpuUser ssCpuSystem ssCpuIdle
      ssCpuRawUser ssCpuRawSystem ssCpuRawIdle ssCpuRawNice)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

sub unix_init {
  my $self = shift;
  my %params = @_;
  my $type = 0;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['loads', 'laTable', 'Classes::UCDMIB::Component::CpuSubsystem::Load'],
  ]);
}

sub unix_check {
  my $self = shift;
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


package Classes::UCDMIB::Component::CpuSubsystem::Load;
our @ISA = qw(Classes::UCDMIB::Component::CpuSubsystem);
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

