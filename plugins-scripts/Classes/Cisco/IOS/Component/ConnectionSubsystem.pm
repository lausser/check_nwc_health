package Classes::Cisco::IOS::Component::ConnectionSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-FIREWALL-MIB', [
      ['connectionstates', 'cfwConnectionStatTable', 'Classes::Cisco::IOS::Component::ConnectionSubsystem::ConnectionState'],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking connection states');
  $self->blacklist('cs', '');
  foreach (@{$self->{connectionstates}}) {
    $_->check();
  }
}


package Classes::Cisco::IOS::Component::ConnectionSubsystem::ConnectionState;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{cfwConnectionStatDescription});
  if ($self->{cfwConnectionStatDescription} !~ /number of connections currently in use/i) {
    $self->add_blacklist(sprintf 'c:%s', $self->{cfwConnectionStatDescription});
    $self->add_info(sprintf '%d connections currently in use',
        $self->{cfwConnectionStatValue}||$self->{cfwConnectionStatCount}, $self->{usage});
  } else {
    $self->add_info(sprintf '%d connections currently in use',
        $self->{cfwConnectionStatValue}, $self->{usage});
    $self->set_thresholds(warning => 500000, critical => 750000);
    $self->add_message($self->check_thresholds($self->{cfwConnectionStatValue}));
    $self->add_perfdata(
        label => 'connections',
        value => $self->{cfwConnectionStatValue},
        warning => $self->{warning},
        critical => $self->{critical}
    );
  }
}

