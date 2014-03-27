package Classes::Cisco::AsyncOS::Component::KeySubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['keys', 'keyExpirationTable', 'Classes::Cisco::AsyncOS::Component::KeySubsystem::Key'],
  ]);
}

package Classes::Cisco::AsyncOS::Component::KeySubsystem::Key;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('k', $self->{keyExpirationIndex});
  $self->{keyDaysUntilExpire} = int($self->{keySecondsUntilExpire} / 86400);
  if ($self->{keyIsPerpetual} eq 'true') {
    $self->add_info(sprintf 'perpetual key %d (%s) never expires',
        $self->{keyExpirationIndex},
        $self->{keyDescription});
    $self->add_ok();
  } else {
    $self->add_info(sprintf 'key %d (%s) expires in %d days',
        $self->{keyExpirationIndex},
        $self->{keyDescription},
        $self->{keyDaysUntilExpire});
    $self->set_thresholds(warning => '14:', critical => '7:');
    $self->add_message($self->check_thresholds($self->{keyDaysUntilExpire}));
  }
  $self->add_perfdata(
      label => sprintf('lifetime_%s', $self->{keyDaysUntilExpire}),
      value => $self->{keyDaysUntilExpire},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

