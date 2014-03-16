package Classes::Cisco::CCM::Component::PhoneSubsystem;
our @ISA = qw(Classes::Cisco::CCM);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('CISCO-CCM-MIB', (qw(
      ccmRegisteredPhones ccmUnregisteredPhones ccmRejectedPhones)));
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'phones: %d registered, %d unregistered, %d rejected',
      $self->{ccmRegisteredPhones},
      $self->{ccmUnregisteredPhones},
      $self->{ccmRejectedPhones});
  $self->set_thresholds(warning => 10, critical => 20);
  $self->add_message($self->check_thresholds($self->{ccmRejectedPhones}));
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

