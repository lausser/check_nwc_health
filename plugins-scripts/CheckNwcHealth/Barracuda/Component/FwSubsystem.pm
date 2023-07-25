package CheckNwcHealth::Barracuda::Component::FwSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::fw::policy::connections/) {
    $self->get_snmp_tables('PHION-MIB', [
      ['fwstats', 'fwStatsTable', 'CheckNwcHealth::Barracuda::Component::FwSubsystem::FWStat'],
    ]);
    $self->get_snmp_objects('PHION-MIB', qw(vpnUsers));
  }
}


package CheckNwcHealth::Barracuda::Component::FwSubsystem::FWStat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->set_thresholds(warning => 300000, critical => 400000);
  $self->add_message($self->check_thresholds($self->{firewallSessions64}),
      sprintf 'fw has %s open sessions', $self->{firewallSessions64});
  $self->add_perfdata(
      label => 'fw_sessions',
      value => $self->{firewallSessions64},
  );
}

