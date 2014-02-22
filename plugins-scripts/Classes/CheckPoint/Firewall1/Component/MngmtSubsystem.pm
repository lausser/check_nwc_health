package Classes::CheckPoint::Firewall1::Component::MngmtSubsystem;
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
  if ($self->mode =~ /device::mngmt::status/) {
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      mgStatShortDescr mgStatLongDescr)));
  }
}

sub check {
  my $self = shift;
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

