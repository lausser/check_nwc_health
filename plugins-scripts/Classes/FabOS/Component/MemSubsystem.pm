package Classes::FabOS::Component::MemSubsystem;
our @ISA = qw(Classes::FabOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    mems => [],
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
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  my $type = 0;
  foreach (qw(swMemUsage swMemUsageLimit1 swMemUsageLimit3 swMemPollingInterval
      swMemNoOfRetries swMemAction)) {
    $self->{$_} = $self->valid_response('SW-MIB', $_, 0);
  }
  foreach (qw(swFwFabricWatchLicense)) {
    $self->{$_} = $self->get_snmp_object('SW-MIB', $_);
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (defined $self->{swMemUsage}) {
    my $info = sprintf 'memory usage is %.2f%%',
        $self->{swMemUsage};
    $self->add_info($info);
    $self->set_thresholds(warning => $self->{swMemUsageLimit1},
        critical => $self->{swMemUsageLimit3});
    $self->add_message($self->check_thresholds($self->{swMemUsage}), $info);
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{swMemUsage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical}
    );
  } elsif ($self->{swFwFabricWatchLicense} eq 'swFwNotLicensed') {
    $self->add_message(UNKNOWN, 'please install a fabric watch license');
  } else {
    $self->add_message(UNKNOWN, 'cannot aquire momory usage');
  }
}

sub dump {
  my $self = shift;
  printf "[MEMORY]\n";
  foreach (qw(swMemUsage swMemUsageLimit1 swMemUsageLimit3 swMemPollingInterval
      swMemNoOfRetries swMemAction)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

