package Classes::Cisco::Viptela::Component::SdwanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-VIPTELA-MIB'} = {};
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-VIPTELA-MIB'}->{configuredConnections} = '1.3.6.1.4.1.9.9.1002.1.1.5.1';
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-VIPTELA-MIB'}->{activeConnections} = '1.3.6.1.4.1.9.9.1002.1.1.5.2';

  $self->get_snmp_objects("CISCO-VIPTELA-MIB", qw(configuredConnections activeConnections));
  $self->{session_availability} = $self->{configuredConnections} == 0 ? 0 : (
      $self->{activeConnections} /
      $self->{configuredConnections}
  ) * 100;
}

sub check {
  my ($self) = @_;
  if ($self->mode eq "device::sdwan::session::availability") {
    $self->add_info(sprintf "%d of %d sessions are active (%.2f%%)",
        $self->{activeConnections},
        $self->{configuredConnections},
        $self->{session_availability});
    $self->set_thresholds(metric => "session_availability",
        warning => "100:",
        critical => "50:");
    $self->add_message($self->check_thresholds(
        metric => "session_availability",
        value => $self->{session_availability}));
    $self->add_perfdata(
        label => 'session_availability',
        value => $self->{session_availability},
        uom => '%',
    );
  }
}

1;
