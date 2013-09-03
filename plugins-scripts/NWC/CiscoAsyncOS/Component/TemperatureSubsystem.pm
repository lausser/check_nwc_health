package NWC::CiscoAsyncOS::Component::TemperatureSubsystem;
our @ISA = qw(NWC::CiscoAsyncOS::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    temperatures => [],
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
  my $tempcnt = 0;
  foreach ($self->get_snmp_table_objects(
      'ASYNCOS-MAIL-MIB', 'temperatureTable')) {
    push(@{$self->{temperatures}},
        NWC::CiscoAsyncOS::Component::TemperatureSubsystem::Temperature->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking temperatures');
  $self->blacklist('t', '');
  if (scalar (@{$self->{temperatures}}) == 0) {
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


package NWC::CiscoAsyncOS::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(NWC::CiscoAsyncOS::Component::TemperatureSubsystem);

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
  foreach (qw(temperatureIndex degreesCelsius temperatureName)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{temperatureIndex});
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_info(sprintf 'temperature %d (%s) is %s degree C',
        $self->{temperatureIndex},
        $self->{temperatureName},
        $self->{degreesCelsius});
  if ($self->check_thresholds($self->{degreesCelsius})) {
    $self->add_message($self->check_thresholds($self->{degreesCelsius}),
        $self->{info});
  }
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{temperatureIndex}),
      value => $self->{degreesCelsius},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[TEMP_%s]\n", $self->{temperatureIndex};
  foreach (qw(temperatureIndex degreesCelsius temperatureName)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

