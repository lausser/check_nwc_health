package Classes::Juniper::IVE::Component::MemSubsystem;
our @ISA = qw(Classes::Juniper::IVE);

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
  $self->{iveMemoryUtil} = $self->get_snmp_object('JUNIPER-IVE-MIB', 'iveMemoryUtil');
  $self->{iveSwapUtil} = $self->get_snmp_object('JUNIPER-IVE-MIB', 'iveSwapUtil');
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  my $info = sprintf 'memory usage is %.2f%%, swap usage is %.2f%%',
      $self->{iveMemoryUtil}, $self->{iveSwapUtil};
  $self->add_info($info);
  $self->set_thresholds(warning => 90, critical => 95);
  $self->add_message($self->check_thresholds($self->{iveMemoryUtil}),
      sprintf 'memory usage is %.2f%%', $self->{iveMemoryUtil});
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{iveMemoryUtil},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
  );
  $self->set_thresholds(warning => 5, critical => 10);
  $self->add_message($self->check_thresholds($self->{iveSwapUtil}),
      sprintf 'swap usage is %.2f%%', $self->{iveSwapUtil});
  $self->add_perfdata(
      label => 'swap_usage',
      value => $self->{iveSwapUtil},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
  );
}

sub dump {
  my $self = shift;
  printf "[MEMORY/SWAP]\n";
  foreach (qw(iveMemoryUtil iveSwapUtil)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

