package Classes::CiscoCCM::Component::PhoneSubsystem;
our @ISA = qw(Classes::CiscoCCM);
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
  my %params = @_;
  foreach (qw(ccmRegisteredPhones ccmUnregisteredPhones ccmRejectedPhones)) {
    $self->{$_} = $self->get_snmp_object('CISCO-CCM-MIB', $_, 0);
  }
}

sub check {
  my $self = shift;
  my $info = sprintf 'phones: %d registered, %d unregistered, %d rejected',
      $self->{ccmRegisteredPhones},
      $self->{ccmUnregisteredPhones},
      $self->{ccmRejectedPhones};
  $self->add_info($info);
  $self->set_thresholds(warning => 10, critical => 20);
  $self->add_message($self->check_thresholds($self->{ccmRejectedPhones}), $info);
  $self->add_perfdata(
      label => 'registered',
      value => $self->{ccmRegisteredPhones},
  );
  $self->add_perfdata(
      label => 'unregistered',
      value => $self->{ccmUnregisteredPhones},
  );
  $self->add_perfdata(
      label => 'rejected',
      value => $self->{ccmRejectedPhones},
  );
}

sub dump {
  my $self = shift;
  printf "[PHONES]\n";
  foreach (qw(ccmRegisteredPhones ccmUnregisteredPhones ccmRejectedPhones)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}

1;
