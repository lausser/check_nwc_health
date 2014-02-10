package Classes::CiscoIOS::Component::ConnectionSubsystem;
our @ISA = qw(Classes::CiscoIOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    connectionstates => [],
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
  my $type = 0;
  foreach ($self->get_snmp_table_objects(
     'CISCO-FIREWALL-MIB', 'cfwConnectionStatTable')) {
    push(@{$self->{connectionstates}},
        Classes::CiscoIOS::Component::ConnectionSubsystem::ConnectionState->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking connection states');
  $self->blacklist('cs', '');
  if (scalar (@{$self->{connectionstates}}) == 0) {
  } else {
    foreach (@{$self->{connectionstates}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{connectionstates}}) {
    $_->dump();
  }
}


package Classes::CiscoIOS::Component::ConnectionSubsystem::ConnectionState;
our @ISA = qw(Classes::CiscoIOS::Component::ConnectionSubsystem);

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
  foreach (qw(cfwConnectionStatService cfwConnectionStatType cfwConnectionStatDescription
      cfwConnectionStatCount cfwConnectionStatValue)) {
    $self->{$_} = $params{$_} || "";
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{cfwConnectionStatDescription});
  if ($self->{cfwConnectionStatDescription} !~ /number of connections currently in use/i) {
    $self->add_blacklist(sprintf 'c:%s', $self->{cfwConnectionStatDescription});
    $self->add_info(sprintf '%d connections currently in use',
        $self->{cfwConnectionStatValue}||$self->{cfwConnectionStatCount}, $self->{usage});
  } else {
    my $info = sprintf '%d connections currently in use',
        $self->{cfwConnectionStatValue}, $self->{usage};
    $self->add_info($info);
    $self->set_thresholds(warning => 500000, critical => 750000);
    $self->add_message($self->check_thresholds($self->{cfwConnectionStatValue}), $info);
    $self->add_perfdata(
        label => 'connections',
        value => $self->{cfwConnectionStatValue},
        warning => $self->{warning},
        critical => $self->{critical}
    );
  }
}

sub dump {
  my $self = shift;
  printf "[CONNECTIONSTATS_%s]\n", $self->{cfwConnectionStatType};
  foreach (qw(cfwConnectionStatService cfwConnectionStatType cfwConnectionStatDescription
      cfwConnectionStatCount cfwConnectionStatValue)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

