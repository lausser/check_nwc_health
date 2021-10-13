package Classes::PulseSecure::Gateway::Component::UserSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  # https://kb.pulsesecure.net/articles/Pulse_Secure_Article/KB44150
  $self->get_snmp_objects('PULSESECURE-PSG-MIB', (qw(
      iveSSLConnections iveVPNTunnels 
      signedInWebUsers signedInMailUsers
      iveConcurrentUsers clusterConcurrentUsers iveTotalSignedInUsers
      maxLicensedUsers)));
  foreach (qw(
      iveSSLConnections iveVPNTunnels 
      signedInWebUsers signedInMailUsers
      iveConcurrentUsers clusterConcurrentUsers iveTotalSignedInUsers)) {
    $self->{$_} = 0 if ! defined $self->{$_};
  }
}

sub check {
  my ($self) = @_;
# info signedInWebUsers iveConcurrentUsers 

# info but trap clusterConcurrentUsers+maxLicensedUsers
  $self->add_info('checking memory');
  if (defined $self->{maxLicensedUsers}) {
    $self->add_info(sprintf 'Users: cluster=%d (of %d), node=%d, web=%d, mail=%d, vpn=%d, ssl=%d',
        $self->{clusterConcurrentUsers},
        $self->{maxLicensedUsers},
        $self->{iveConcurrentUsers},
        $self->{signedInWebUsers},
        $self->{signedInMailUsers},
        $self->{iveVPNTunnels},
        $self->{iveSSLConnections}
    );
    $self->{license_usage} = 100 * $self->{iveConcurrentUsers} /
        $self->{maxLicensedUsers};
    $self->{cluster_license_usage} = 100 * $self->{clusterConcurrentUsers} /
        $self->{maxLicensedUsers};
    $self->set_thresholds(metric => "license_usage",
        warning => 90, critical => 95);
    $self->add_message($self->check_thresholds(metric => "license_usage",
        value => $self->{license_usage}));
    $self->add_perfdata(
        label => 'license_usage',
        value => $self->{license_usage},
        uom => "%",
    );
  } else {
    $self->add_info(sprintf 'Users: cluster=%d, node=%d, web=%d, mail=%d, vpn=%d, ssl=%d',
        $self->{clusterConcurrentUsers},
        $self->{iveConcurrentUsers},
        $self->{signedInWebUsers},
        $self->{signedInMailUsers},
        $self->{iveVPNTunnels},
        $self->{iveSSLConnections}
    );
    $self->set_thresholds(metric => "concurrent_users",
        warning => 1000, critical => 1500);
    $self->add_message($self->check_thresholds(metric => "concurrent_users",
        value => $self->{iveConcurrentUsers}));
  }
  $self->add_perfdata(
      label => 'cluster_concurrent_users',
      value => $self->{clusterConcurrentUsers},
  );
  $self->add_perfdata(
      label => 'concurrent_users',
      value => $self->{iveConcurrentUsers},
  );
  $self->add_perfdata(
      label => 'web_users',
      value => $self->{signedInWebUsers},
  );
  $self->add_perfdata(
      label => 'vpn_tunnels',
      value => $self->{iveVPNTunnels},
  );
}

__END__

Beispiel
Knoten a
[USERSUBSYSTEM]
clusterConcurrentUsers: 153
iveConcurrentUsers: 153
iveSSLConnections: 153
iveTotalSignedInUsers: 153
iveVPNTunnels: 152
license_usage: 76.5
maxLicensedUsers: 200 <- nicht bestaetigt, dass es den wert offiziell gibt. knoten oder cluster?
signedInMailUsers: 0
signedInWebUsers: 153

Knoten b
[USERSUBSYSTEM]
clusterConcurrentUsers: 153
iveConcurrentUsers: 0
iveSSLConnections: 0
iveTotalSignedInUsers: 153 <- identisch mit clusterConcurrentUsers?
iveVPNTunnels: 0
license_usage: 76.5
maxLicensedUsers: 200
signedInMailUsers: 0
signedInWebUsers: 153 <- vermutlich clusterweit

iveTotalSignedInUsers 1.3.6.1.4.1.12532.48
"The Total number of Users Logged In for the Cluster"
iveConcurrentUsers 1.3.6.1.4.1.12532.12
"The Total number of Concurrent user Licenses used for the IVE Node"
clusterConcurrentUsers 1.3.6.1.4.1.12532.13
"The Total number of Concurrent user Licenses used for the Cluster"
