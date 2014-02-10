package Classes::Juniper::IVE::Component::UserSubsystem;
our @ISA = qw(Classes::Juniper::IVE);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    mems => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  foreach (qw(signedInWebUsers signedInMailUsers meetingUserCount iveConcurrentUsers clusterConcurrentUsers)) {
    $self->{$_} = $self->valid_response('JUNIPER-IVE-MIB', $_) || 0;
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  my $info = sprintf 'Users:  cluster=%d, node=%d, web=%d, mail=%d, meeting=%d',
      $self->{clusterConcurrentUsers}, $self->{iveConcurrentUsers},
      $self->{signedInWebUsers},
      $self->{signedInMailUsers},
      $self->{meetingUserCount};
  $self->add_info($info);
  $self->add_message(OK, $info);
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

sub dump {
  my $self = shift;
  printf "[USERS]\n";
  foreach (qw(signedInWebUsers signedInMailUsers meetingUserCount iveConcurrentUsers clusterConcurrentUsers)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

