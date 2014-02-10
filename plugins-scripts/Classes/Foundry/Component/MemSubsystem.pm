package Classes::Foundry::Component::MemSubsystem;
our @ISA = qw(Classes::Foundry);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    mems => [],
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
  foreach (qw(snAgGblDynMemUtil snAgGblDynMemTotal snAgGblDynMemFree)) {
    $self->{$_} = $self->get_snmp_object('FOUNDRY-SN-AGENT-MIB', $_);
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (defined $self->{snAgGblDynMemUtil}) {
    my $info = sprintf 'memory usage is %.2f%%',
        $self->{snAgGblDynMemUtil};
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 99);
    $self->add_message($self->check_thresholds($self->{snAgGblDynMemUtil}), $info);
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{snAgGblDynMemUtil},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical}
    );
  } else {
    $self->add_message(UNKNOWN, 'cannot aquire momory usage');
  }
}

sub dump {
  my $self = shift;
  printf "[MEMORY]\n";
  foreach (qw(snAgGblDynMemUtil snAgGblDynMemTotal snAgGblDynMemFree)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

