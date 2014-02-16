package Classes::Juniper::NetScreen::Component::CpuSubsystem;
our @ISA = qw(Classes::Juniper::NetScreen);
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
  foreach (qw(nsResCpuAvg)) {
    $self->{$_} = $self->get_snmp_object('NETSCREEN-RESOURCE-MIB', $_);
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('c', undef);
  my $info = sprintf 'cpu usage is %.2f%%', $self->{nsResCpuAvg};
  $self->add_info($info);
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{nsResCpuAvg}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{nsResCpuAvg},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(nsResCpuAvg
      )) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package Classes::Juniper::NetScreen::Component::CpuSubsystem::Load;
our @ISA = qw(Classes::Juniper::NetScreen::Component::CpuSubsystem);
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

