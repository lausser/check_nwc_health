package Classes::HP::Procurve::Component::CpuSubsystem;
our @ISA = qw(Classes::HP::Procurve);
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
  my %params = @_;
  $self->{hpSwitchCpuStat} = $self->get_snmp_object('STATISTICS-MIB', 'hpSwitchCpuStat');
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  my $info = sprintf 'cpu usage is %.2f%%', $self->{hpSwitchCpuStat};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90); # maybe lower, because the switching is done in hardware
  $self->add_message($self->check_thresholds($self->{hpSwitchCpuStat}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{hpSwitchCpuStat},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(hpSwitchCpuStat)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

