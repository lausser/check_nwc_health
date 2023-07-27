package CheckNwcHealth::Cisco::CCM::Component::PhoneSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-CCM-MIB', (qw(
      ccmRegisteredPhones ccmUnregisteredPhones ccmRejectedPhones)));
  if (! defined $self->{ccmRegisteredPhones}) {
    $self->get_snmp_tables('CISCO-CCM-MIB', [
        ['ccms', 'ccmTable', 'CheckNwcHealth::Cisco::CCM::Component::CmSubsystem::Cm'],
    ]);
  }
}

sub check {
  my ($self) = @_;
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

  $self->set_thresholds(metric => 'registered',
      warning => '0:', critical => '0:');
  $self->set_level($self->check_thresholds(metric => 'registered',
      value => $self->{ccmRegisteredPhones}));

  $self->set_thresholds(metric => 'unregistered',
      warning => 11, critical => 22);
  $self->set_level($self->check_thresholds(metric => 'unregistered',
      value => $self->{ccmUnregisteredPhones}));

  $self->set_thresholds(metric => 'rejected',
      warning => 110, critical => 120);
  $self->set_level($self->check_thresholds(metric => 'rejected',
      value => $self->{ccmRejectedPhones}));

  $self->add_message($self->get_level());

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

