package NWC::CiscoWLC::Component::CpuSubsystem;
our @ISA = qw(NWC::CiscoWLC);

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
  $self->{cpu_utilization} = $self->get_snmp_object(
      'AIRESPACE-SWITCHING-MIB', 'agentCurrentCPUUtilization');
}

sub check {
  my $self = shift;
  my $info = sprintf 'cpu usage is %.2f%%',
      $self->{cpu_utilization};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{cpu_utilization}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_utilization},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(cpu_utilization)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

