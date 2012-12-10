package NWC::CheckPoint::Firewall1::Component::HaSubsystem;
our @ISA = qw(NWC::CheckPoint::Firewall1);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    cpus => [],
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
  if ($self->mode =~ /device::ha::role/) {
    $self->{haStarted} = $self->get_snmp_object('CHECKPOINT-MIB', 'haStarted');
    $self->{haState} = $self->get_snmp_object('CHECKPOINT-MIB', 'haState');
    $self->{haStatShort} = $self->get_snmp_object('CHECKPOINT-MIB', 'haStatShort');
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
}

sub check {
  my $self = shift;
  my %params = @_;
  my $errorfound = 0;
  $self->add_info('checking ha');
  my $info = sprintf 'ha %sstarted, role is %s, status is %s', 
      $self->{haStarted} eq 'yes' ? '' : 'not ', 
      $self->{haState}, $self->{haStatShort};
  $self->add_info($info);
  if ($self->{haStarted} eq 'yes') {
    if ($self->{haStatShort} ne 'OK') {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : 2,
          $info);
    } elsif ($self->{haState} ne $self->opts->role()) {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : 1,
          $info);
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : 1,
          sprintf "expected role %s", $self->opts->role())
    } else {
      $self->add_message(OK, $info);
    }
  } else {
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() : 1,
        'ha was not started');
  }

  #$self->add_message($self->check_thresholds($self->{procUsage}), $info);
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(procUsage procQueue)) {
    printf "%s: %s\n", $_, $self->{$_} if defined $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

