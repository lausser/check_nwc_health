package CheckNwcHealth::Juniper::IVE::Component::UserSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('JUNIPER-IVE-MIB', (qw(
      iveSSLConnections iveVPNTunnels 
      signedInWebUsers signedInMailUsers meetingUserCount
      iveConcurrentUsers clusterConcurrentUsers)));
  foreach (qw(
      iveSSLConnections iveVPNTunnels 
      signedInWebUsers signedInMailUsers meetingUserCount
      iveConcurrentUsers clusterConcurrentUsers)) {
    $self->{$_} = 0 if ! defined $self->{$_};
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'Users: sslconns=%d cluster=%d, node=%d, web=%d, mail=%d, meeting=%d',
      $self->{iveSSLConnections},
      $self->{clusterConcurrentUsers},
      $self->{iveConcurrentUsers},
      $self->{signedInWebUsers},
      $self->{signedInMailUsers},
      $self->{meetingUserCount});
  $self->add_ok();
  $self->add_perfdata(
      label => 'sslconns',
      value => $self->{iveSSLConnections},
  );
  $self->add_perfdata(
      label => 'web_users',
      value => $self->{signedInWebUsers},
  );
  $self->add_perfdata(
      label => 'mail_users',
      value => $self->{signedInMailUsers},
  );
  $self->add_perfdata(
      label => 'meeting_users',
      value => $self->{meetingUserCount},
  );
  $self->add_perfdata(
      label => 'concurrent_users',
      value => $self->{iveConcurrentUsers},
  );
  $self->add_perfdata(
      label => 'cluster_concurrent_users',
      value => $self->{clusterConcurrentUsers},
  );
}
