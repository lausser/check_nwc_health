package NWC::CiscoIOS::Component::ConnectionSubsystem;
our @ISA = qw(NWC::CiscoIOS);

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
        NWC::CiscoIOS::Component::ConnectionSubsystem::ConnectionState->new(%{$_}));
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


package NWC::CiscoIOS::Component::ConnectionSubsystem::ConnectionState;
our @ISA = qw(NWC::CiscoIOS::Component::ConnectionSubsystem);

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
######repairme
  $self->blacklist('m', $self->{cfwConnectionStatType});
  my $info = sprintf 'mempool %s usage is %.2f%%',
      $self->{ciscoConnectionlName}, $self->{usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}), $info);

  $self->add_perfdata(
      label => $self->{ciscoConnectionoryPoolName}.'_usage',
      value => $self->{usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
  );
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

