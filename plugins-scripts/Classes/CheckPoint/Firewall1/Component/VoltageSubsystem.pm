package Classes::CheckPoint::Firewall1::Component::VoltageSubsystem;
our @ISA = qw(Classes::CheckPoint::Firewall1);
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
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['voltages', 'sensorsVoltageTable', 'Classes::CheckPoint::Firewall1::Component::VoltageSubsystem::Voltage'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{voltages}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{voltages}}) {
    $_->dump();
  }
}


package Classes::CheckPoint::Firewall1::Component::VoltageSubsystem::Voltage;
our @ISA = qw(Classes::CheckPoint::Firewall1::Component::VoltageSubsystem);
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
  foreach (qw(sensorsVoltageIndex sensorsVoltageName sensorsVoltageValue
      sensorsVoltageUOM sensorsVoltageType sensorsVoltageStatus)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->blacklist('t', $self->{sensorsVoltageIndex});
  my $info = sprintf 'voltage %s is %s (%.2f %s)', 
      $self->{sensorsVoltageName}, $self->{sensorsVoltageStatus},
      $self->{sensorsVoltageValue}, $self->{sensorsVoltageUOM};
  $self->add_info($info);
  if ($self->{sensorsVoltageStatus} eq 'normal') {
    $self->add_message(OK, $info);
  } elsif ($self->{sensorsVoltageStatus} eq 'abnormal') {
    $self->add_message(CRITICAL, $info);
  } else {
    $self->add_message(UNKNOWN, $info);
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'voltage'.$self->{sensorsVoltageName}.'_rpm',
      value => $self->{sensorsVoltageValue},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[VOLTAGE_%s]\n", $self->{sensorsVoltageIndex};
  foreach (qw(sensorsVoltageIndex sensorsVoltageName sensorsVoltageValue
      sensorsVoltageUOM sensorsVoltageType sensorsVoltageStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info} || "unchecked";
  printf "\n";
}


