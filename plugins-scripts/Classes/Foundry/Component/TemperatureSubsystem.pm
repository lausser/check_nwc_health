package Classes::Foundry::Component::TemperatureSubsystem;
our @ISA = qw(Classes::Foundry);
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
  my $temp = 0;
  foreach ($self->get_snmp_table_objects(
      'FOUNDRY-SN-AGENT-MIB', 'snAgentTempTable')) {
    $_->{snAgentTempSlotNum} ||= $temp++;
    $_->{snAgentTempSensorId} ||= 1;
    push(@{$self->{temperatures}},
        Classes::Foundry::Component::TemperatureSubsystem::Temperature->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  if (scalar (@{$self->{temperatures}}) == 0) {
    $self->overall_check();
  } else {
    foreach (@{$self->{temperatures}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{temperatures}}) {
    $_->dump();
  }
}


package Classes::Foundry::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Classes::Foundry::Component::TemperatureSubsystem);
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
  foreach (qw(snAgentTempSlotNum snAgentTempSensorId snAgentTempSensorDescr 
      snAgentTempValue)) {
    $self->{$_} = $params{$_};
  }
  $self->{snAgentTempValue} /= 2;
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->blacklist('t', undef);
  my $info = sprintf 'temperature %s is %.2fC', 
      $self->{snAgentTempSlotNum}, $self->{snAgentTempValue};
  $self->add_info($info);
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_message($self->check_thresholds($self->{snAgentTempValue}), $info);
  $self->add_perfdata(
      label => 'temperature_'.$self->{snAgentTempSlotNum},
      value => $self->{snAgentTempValue},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[TEMP_%s]\n", $self->{snAgentTempSlotNum};
  foreach (qw(snAgentTempSlotNum snAgentTempSensorId snAgentTempSensorDescr 
      snAgentTempValue)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info} || "unchecked";
  printf "\n";
}


