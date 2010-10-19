package NWC::Cisco::Component::MemSubsystem;
our @ISA = qw(NWC::Cisco);

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
  # ciscoEnvMonMemStatusTable 
  my $oids = {
      ciscoMemoryPoolTable => '1.3.6.1.4.1.9.9.48.1.1',
      ciscoMemoryPoolEntry => '1.3.6.1.4.1.9.9.48.1.1.1',
      ciscoMemoryPoolType => '1.3.6.1.4.1.9.9.48.1.1.1.1',
      ciscoMemoryPoolName => '1.3.6.1.4.1.9.9.48.1.1.1.2',
      ciscoMemoryPoolAlternate => '1.3.6.1.4.1.9.9.48.1.1.1.3',
      ciscoMemoryPoolValid => '1.3.6.1.4.1.9.9.48.1.1.1.4',
      ciscoMemoryPoolUsed => '1.3.6.1.4.1.9.9.48.1.1.1.5',
      ciscoMemoryPoolFree => '1.3.6.1.4.1.9.9.48.1.1.1.6',
      ciscoMemoryPoolLargestFree => '1.3.6.1.4.1.9.9.48.1.1.1.7',
  };
  # INDEX { ciscoMemoryPoolType }
  my $type = 0;
  foreach ($self->get_entries($oids, 'ciscoMemoryPoolEntry')) {
    $_->{ciscoMemoryPoolType} ||= $type++;
    push(@{$self->{mems}},
        NWC::Cisco::Component::MemSubsystem::Mem->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking mems');
  $self->blacklist('ff', '');
  if (scalar (@{$self->{mems}}) == 0) {
  } else {
    foreach (@{$self->{mems}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{mems}}) {
    $_->dump();
  }
}


package NWC::Cisco::Component::MemSubsystem::Mem;
our @ISA = qw(NWC::Cisco::Component::MemSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    ciscoMemoryPoolTable => $params{ciscoMemoryPoolTable},
    ciscoMemoryPoolEntry => $params{ciscoMemoryPoolEntry},
    ciscoMemoryPoolType => $params{ciscoMemoryPoolType},
    ciscoMemoryPoolName => $params{ciscoMemoryPoolName},
    ciscoMemoryPoolAlternate => $params{ciscoMemoryPoolAlternate},
    ciscoMemoryPoolValid => $params{ciscoMemoryPoolValid},
    ciscoMemoryPoolUsed => $params{ciscoMemoryPoolUsed},
    ciscoMemoryPoolFree => $params{ciscoMemoryPoolFree},
    ciscoMemoryPoolLargestFree => $params{ciscoMemoryPoolLargestFree},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->{usage} = 100 * $params{ciscoMemoryPoolUsed} /
      ($params{ciscoMemoryPoolFree} + $params{ciscoMemoryPoolUsed});
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('m', $self->{ciscoMemoryPoolType});
  my $info = sprintf 'mempool %s usage is %.2f%%',
      $self->{ciscoMemoryPoolName}, $self->{usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}), $info);

  $self->add_perfdata(
      label => $self->{ciscoMemoryPoolName}.'_usage',
      value => $self->{usage},
      uom => '%',
      warning => $self->{warningthreshold},
      critical => $self->{criticalthreshold}
  );
}

sub dump {
  my $self = shift;
  printf "[MEMPOOL_%s]\n", $self->{ciscoMemoryPoolType};
  foreach (qw(ciscoMemoryPoolType ciscoMemoryPoolName ciscoMemoryPoolAlternate ciscoMemoryPoolValid ciscoMemoryPoolUsed ciscoMemoryPoolFree ciscoMemoryPoolLargestFree)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

