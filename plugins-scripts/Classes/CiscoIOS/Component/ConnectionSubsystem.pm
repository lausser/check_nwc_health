package Classes::CiscoIOS::Component::ConnectionSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  my $type = 0;
  $self->get_snmp_tables('CISCO-FIREWALL-MIB', [
      ['connectionstates', 'cfwConnectionStatTable', 'Classes::CiscoIOS::Component::ConnectionSubsystem::ConnectionState'],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking connection states');
  $self->blacklist('cs', '');
  if (scalar (@{$self->{connectionstates}}) == 0) {
  } else {
    foreach (@{$self->{connectionstates}}) {
      $_->check();
    }
  }
}


package Classes::CiscoIOS::Component::ConnectionSubsystem::ConnectionState;
our @ISA = qw(GLPlugin::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{cfwConnectionStatDescription});
  if ($self->{cfwConnectionStatDescription} !~ /number of connections currently in use/i) {
    $self->add_blacklist(sprintf 'c:%s', $self->{cfwConnectionStatDescription});
    $self->add_info(sprintf '%d connections currently in use',
        $self->{cfwConnectionStatValue}||$self->{cfwConnectionStatCount}, $self->{usage});
  } else {
    my $info = sprintf '%d connections currently in use',
        $self->{cfwConnectionStatValue}, $self->{usage};
    $self->add_info($info);
    $self->set_thresholds(warning => 500000, critical => 750000);
    $self->add_message($self->check_thresholds($self->{cfwConnectionStatValue}), $info);
    $self->add_perfdata(
        label => 'connections',
        value => $self->{cfwConnectionStatValue},
        warning => $self->{warning},
        critical => $self->{critical}
    );
  }
}

