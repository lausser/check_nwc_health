package NWC::CiscoIOS::Component::MemSubsystem;
our @ISA = qw(NWC::CiscoIOS);

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
  foreach ($self->get_snmp_table_objects(
     'CISCO-MEMORY-POOL-MIB', 'ciscoMemoryPoolTable')) {
    $_->{ciscoMemoryPoolType} ||= $type++;
    push(@{$self->{mems}},
        NWC::CiscoIOS::Component::MemSubsystem::Mem->new(%{$_}));
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


package NWC::CiscoIOS::Component::MemSubsystem::Mem;
our @ISA = qw(NWC::CiscoIOS::Component::MemSubsystem);

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
  foreach my $param (qw(ciscoMemoryPoolTable ciscoMemoryPoolEntry
      ciscoMemoryPoolType ciscoMemoryPoolName ciscoMemoryPoolAlternate
      ciscoMemoryPoolValid ciscoMemoryPoolUsed ciscoMemoryPoolFree
      ciscoMemoryPoolLargestFree)) {
    $self->{$param} = $params{$param};
  }
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
  if ($self->{ciscoMemoryPoolName} eq 'lsmpi_io' && 
      $self->get_snmp_object('MIB-II', 'sysDescr', 0) =~ /IOS.*XE/i) {
    # https://supportforums.cisco.com/docs/DOC-16425
    $self->set_thresholds(warning => 100, critical => 100);
  } else {
    $self->set_thresholds(warning => 80, critical => 90);
  }
  $self->add_message($self->check_thresholds($self->{usage}), $info);

  $self->add_perfdata(
      label => $self->{ciscoMemoryPoolName}.'_usage',
      value => $self->{usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
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

