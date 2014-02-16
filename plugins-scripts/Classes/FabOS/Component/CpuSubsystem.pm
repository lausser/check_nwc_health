package Classes::FabOS::Component::CpuSubsystem;
our @ISA = qw(Classes::FabOS);
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
  my $type = 0;
  foreach (qw(swCpuUsage swCpuNoOfRetries swCpuUsageLimit swCpuPollingInterval
      swCpuAction)) {
    $self->{$_} = $self->valid_response('SW-MIB', $_, 0);
  }
  foreach (qw(swFwFabricWatchLicense)) {
    $self->{$_} = $self->get_snmp_object('SW-MIB', $_);
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  $self->blacklist('c', undef);
  if (defined $self->{swCpuUsage}) {
    my $info = sprintf 'cpu usage is %.2f%%', $self->{swCpuUsage};
    $self->add_info($info);
    $self->set_thresholds(warning => $self->{swCpuUsageLimit},
        critical => $self->{swCpuUsageLimit});
    $self->add_message($self->check_thresholds($self->{swCpuUsage}), $info);
    $self->add_perfdata(
        label => 'cpu_usage',
        value => $self->{swCpuUsage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
  } elsif ($self->{swFwFabricWatchLicense} eq 'swFwNotLicensed') {
    $self->add_message(UNKNOWN, 'please install a fabric watch license');
  } else {
    $self->add_message(UNKNOWN, 'cannot aquire momory usage');
  }
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(swCpuUsage swCpuNoOfRetries swCpuUsageLimit swCpuPollingInterval
      swCpuAction)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

