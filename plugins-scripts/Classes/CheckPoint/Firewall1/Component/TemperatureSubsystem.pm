package Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem;
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
      ['temperatures', 'sensorsTemperatureTable', 'Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem::Temperature'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{temperatures}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{temperatures}}) {
    $_->dump();
  }
}


package Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem);
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
  foreach (qw(sensorsTemperatureIndex sensorsTemperatureName sensorsTemperatureValue
      sensorsTemperatureUOM sensorsTemperatureType sensorsTemperatureStatus)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->blacklist('t', $self->{sensorsTemperatureIndex});
  my $info = sprintf 'temperature %s is %s (%d %s)', 
      $self->{sensorsTemperatureName}, $self->{sensorsTemperatureStatus},
      $self->{sensorsTemperatureValue}, $self->{sensorsTemperatureUOM};
  $self->add_info($info);
  if ($self->{sensorsTemperatureStatus} eq 'normal') {
    $self->add_ok($info);
  } elsif ($self->{sensorsTemperatureStatus} eq 'abnormal') {
    $self->add_critical($info);
  } else {
    $self->add_unknown($info);
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'temperature_'.$self->{sensorsTemperatureName},
      value => $self->{sensorsTemperatureValue},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[TEMP_%s]\n", $self->{sensorsTemperatureIndex};
  foreach (qw(sensorsTemperatureIndex sensorsTemperatureName sensorsTemperatureValue
      sensorsTemperatureUOM sensorsTemperatureType sensorsTemperatureStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info} || "unchecked";
  printf "\n";
}


