package Classes::Juniper::IVE::Component::UserSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('JUNIPER-IVE-MIB', (qw(
      signedInWebUsers signedInMailUsers meetingUserCount
      iveConcurrentUsers clusterConcurrentUsers)));
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  $self->add_info(sprintf 'Users:  cluster=%d, node=%d, web=%d, mail=%d, meeting=%d',
      $self->{clusterConcurrentUsers}, $self->{iveConcurrentUsers},
      $self->{signedInWebUsers},
      $self->{signedInMailUsers},
      $self->{meetingUserCount});
  $self->add_ok();
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

