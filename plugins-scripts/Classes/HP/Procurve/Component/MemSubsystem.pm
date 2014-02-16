package Classes::HP::Procurve::Component::MemSubsystem;
our @ISA = qw(Classes::HP::Procurve::Component::EnvironmentalSubsystem);
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
  foreach ($self->get_snmp_table_objects(
      'NETSWITCH-MIB', 'hpLocalMemTable')) {
    push(@{$self->{mem}}, 
        Classes::HP::Procurve::Component::MemSubsystem::Memory->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (scalar (@{$self->{mem}}) == 0) {
  } else {
    foreach (@{$self->{mem}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{mem}}) {
    $_->dump();
  }
}


package Classes::HP::Procurve::Component::MemSubsystem::Memory;
our @ISA = qw(Classes::HP::Procurve::Component::MemSubsystem);
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
  foreach (qw(hpLocalMemSlotIndex  hpLocalMemSlabCnt
      hpLocalMemFreeSegCnt hpLocalMemAllocSegCnt hpLocalMemTotalBytes
      hpLocalMemFreeBytes hpLocalMemAllocBytes)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('m', $self->{hpicfMemIndex});
  $self->{usage} = $self->{hpLocalMemAllocBytes} / 
      $self->{hpLocalMemTotalBytes} * 100;
  my $info = sprintf 'memory %s usage is %.2f',
      $self->{hpLocalMemSlotIndex},
      $self->{usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}), $info);
  $self->add_perfdata(
      label => 'memory_'.$self->{hpLocalMemSlotIndex}.'_usage',
      value => $self->{usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
  );
}

sub dump {
  my $self = shift;
  printf "[MEM%s]\n", $self->{hpLocalMemSlotIndex};
  foreach (qw(hpLocalMemSlotIndex  hpLocalMemSlabCnt
      hpLocalMemFreeSegCnt hpLocalMemAllocSegCnt hpLocalMemTotalBytes
      hpLocalMemFreeBytes hpLocalMemAllocBytes)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


