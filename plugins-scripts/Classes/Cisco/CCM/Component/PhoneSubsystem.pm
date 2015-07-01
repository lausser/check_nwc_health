package Classes::Cisco::CCM::Component::PhoneSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('CISCO-CCM-MIB', (qw(
      ccmRegisteredPhones ccmUnregisteredPhones ccmRejectedPhones)));
  if (! defined $self->{ccmRegisteredPhones}) {
    $self->get_snmp_tables('CISCO-CCM-MIB', [
        ['ccms', 'ccmTable', 'Classes::Cisco::CCM::Component::CmSubsystem::Cm'],
    ]);
  }
}

sub check {
  my $self = shift;
  if (! defined $self->{ccmRegisteredPhones}) {
    foreach (qw(ccmRegisteredPhones ccmUnregisteredPhones ccmRejectedPhones)) {
      $self->{$_} = 0;
    }
    if (! scalar(@{$self->{ccms}})) {
      $self->add_ok('cm is down');
    } else {
      $self->add_unknown('unable to count phones');
    }
  }
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

