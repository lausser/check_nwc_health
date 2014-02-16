package Classes::F5::F5BIGIP::Component::TemperatureSubsystem;
our @ISA = qw(Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem);
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
      'F5-BIGIP-SYSTEM-MIB', 'sysChassisTempTable')) {
    push(@{$self->{temperatures}},
        Classes::F5::F5BIGIP::Component::TemperatureSubsystem::Temperature->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking temperatures');
  $self->blacklist('tt', '');
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


package Classes::F5::F5BIGIP::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Classes::F5::F5BIGIP::Component::TemperatureSubsystem);
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
  foreach(qw(sysChassisTempIndex sysChassisTempTemperature)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{sysChassisTempIndex});
  $self->add_info(sprintf 'chassis temperature %d is %sC',
      $self->{sysChassisTempIndex},
      $self->{sysChassisTempTemperature});
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{sysChassisTempIndex}),
      value => $self->{sysChassisTempTemperature},
      warning => undef,
      critical => undef,
  );
}

sub dump {
  my $self = shift;
  printf "[TEMP_%s]\n", $self->{sysChassisTempIndex};
  foreach(qw(sysChassisTempIndex sysChassisTempTemperature)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

