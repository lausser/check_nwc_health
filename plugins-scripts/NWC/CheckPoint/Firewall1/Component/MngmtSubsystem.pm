package NWC::CheckPoint::Firewall1::Component::MngmtSubsystem;
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
  if ($self->mode =~ /device::mngmt::status/) {
    $self->{mgStatShortDescr} = $self->get_snmp_object('CHECKPOINT-MIB', 'mgStatShortDescr');
    $self->{mgStatLongDescr} = $self->get_snmp_object('CHECKPOINT-MIB', 'mgStatLongDescr');
  }
}

sub check {
  my $self = shift;
  my %params = @_;
  my $errorfound = 0;
  $self->add_info('checking mngmt');
  if ($self->mode =~ /device::mngmt::status/) {
    if ($self->{mgStatShortDescr} ne 'OK') {
      $self->add_message(CRITICAL,
          sprintf 'status of management is %s', $self->{mgStatLongDescr});
    } else {
      $self->add_message(OK,
          sprintf 'status of management is %s', $self->{mgStatLongDescr});
    }
  }
}

sub dump {
  my $self = shift;
  printf "[MNGMT]\n";
}

