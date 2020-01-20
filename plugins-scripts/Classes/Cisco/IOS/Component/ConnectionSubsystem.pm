package Classes::Cisco::IOS::Component::ConnectionSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-FIREWALL-MIB', [
      ['connectionstates', 'cfwConnectionStatTable', 'Classes::Cisco::IOS::Component::ConnectionSubsystem::ConnectionState'],
  ]);
}

package Classes::Cisco::IOS::Component::ConnectionSubsystem::ConnectionState;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cfwConnectionStatDescription} !~ /number of connections currently in use/i) {
    $self->add_blacklist(sprintf 'c:%s', $self->{cfwConnectionStatDescription});
    $self->add_info(sprintf '%d connections currently in use',
        ($self->{cfwConnectionStatValue}||$self->{cfwConnectionStatCount}));
  } else {
    $self->add_info(sprintf '%d connections currently in use',
        $self->{cfwConnectionStatValue});
    $self->set_thresholds(warning => 500000, critical => 750000);
    $self->add_message($self->check_thresholds($self->{cfwConnectionStatValue}));
    $self->add_perfdata(
        label => 'connections',
        value => $self->{cfwConnectionStatValue},
    );
  }
}

