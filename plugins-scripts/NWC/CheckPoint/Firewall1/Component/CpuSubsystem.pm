package NWC::CheckPoint::Firewall1::Component::CpuSubsystem;
our @ISA = qw(NWC::CheckPoint::Firewall1);

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
  $self->{procUsage} = $self->get_snmp_object('CHECKPOINT-MIB', 'procUsage');
  $self->{procQueue} = $self->get_snmp_object('CHECKPOINT-MIB', 'procQueue');
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  my $info = sprintf 'cpu usage is %.2f%%', $self->{procUsage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{procUsage}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{procUsage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
  if (defined $self->{procQueue}) {
    $self->add_perfdata(
        label => 'cpu_queue_length',
        value => $self->{procQueue},
    );
  }
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(procUsage procQueue)) {
    printf "%s: %s\n", $_, $self->{$_} if defined $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

