package NWC::HOSTRESOURCESMIB::Component::CpuSubsystem;
our @ISA = qw(NWC::HOSTRESOURCESMIB);

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
  my $cpus = {};
  my $idx = 0;
  foreach ($self->get_snmp_table_objects(
      'HOST-RESOURCES-MIB', 'hrProcessorTable')) {
    $_->{hrProcessorIndex} = $idx++;
    push(@{$self->{cpus}}, 
        NWC::HOSTRESOURCESMIB::Component::CpuSubsystem::Cpu->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  $self->blacklist('cpus', '');
  foreach (@{$self->{cpus}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{cpus}}) {
    $_->dump();
  }
}


package NWC::HOSTRESOURCESMIB::Component::CpuSubsystem::Cpu;
our @ISA = qw(NWC::HOSTRESOURCESMIB::Component::CpuSubsystem);

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
  foreach (qw(hrProcessorIndex hrProcessorLoad)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('cpu', $self->{hrProcessorIndex});
  $self->add_info(sprintf 'cpu %s is %.2f%%',
      $self->{hrProcessorIndex},
      $self->{hrProcessorLoad});
  $self->set_thresholds(warning => '80', critical => '90');
  $self->add_message($self->check_thresholds($self->{hrProcessorLoad}), $self->{info});
  $self->add_perfdata(
      label => sprintf('cpu_%s_usage', $self->{hrProcessorIndex}),
      value => $self->{hrProcessorLoad},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{hrProcessorIndex};
  foreach (qw(hrProcessorIndex hrProcessorLoad)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

