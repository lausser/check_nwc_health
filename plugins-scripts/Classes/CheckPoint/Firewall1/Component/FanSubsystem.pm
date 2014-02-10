package Classes::CheckPoint::Firewall1::Component::FanSubsystem;
our @ISA = qw(Classes::CheckPoint::Firewall1);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    fans => [],
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
  my $temp = 0;
  foreach ($self->get_snmp_table_objects(
      'CHECKPOINT-MIB', 'sensorsFanTable')) {
    push(@{$self->{fans}},
        Classes::CheckPoint::Firewall1::Component::FanSubsystem::Fan->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  foreach (@{$self->{fans}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{fans}}) {
    $_->dump();
  }
}


package Classes::CheckPoint::Firewall1::Component::FanSubsystem::Fan;
our @ISA = qw(Classes::CheckPoint::Firewall1::Component::FanSubsystem);

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
  foreach (qw(sensorsFanIndex sensorsFanName sensorsFanValue
      sensorsFanUOM sensorsFanType sensorsFanStatus)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->blacklist('t', $self->{sensorsFanIndex});
  my $info = sprintf 'fan %s is %s (%d %s)', 
      $self->{sensorsFanName}, $self->{sensorsFanStatus},
      $self->{sensorsFanValue}, $self->{sensorsFanUOM};
  $self->add_info($info);
  if ($self->{sensorsFanStatus} eq 'normal') {
    $self->add_message(OK, $info);
  } elsif ($self->{sensorsFanStatus} eq 'abnormal') {
    $self->add_message(CRITICAL, $info);
  } else {
    $self->add_message(UNKNOWN, $info);
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'fan'.$self->{sensorsFanName}.'_rpm',
      value => $self->{sensorsFanValue},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[FAN_%s]\n", $self->{sensorsFanIndex};
  foreach (qw(sensorsFanIndex sensorsFanName sensorsFanValue
      sensorsFanUOM sensorsFanType sensorsFanStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info} || "unchecked";
  printf "\n";
}


