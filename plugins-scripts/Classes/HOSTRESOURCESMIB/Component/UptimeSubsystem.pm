package Classes::HOSTRESOURCESMIB::Component::UptimeSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my $hrSystemUptime = $self->get_snmp_object('HOST-RESOURCES-MIB', 'hrSystemUptime');
  $self->{uptime} = $self->timeticks($hrSystemUptime);
  $self->debug(sprintf 'uptime: %s', $self->{uptime});
  $self->debug(sprintf 'up since: %s',
      scalar localtime (time - $self->{uptime}));
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'device is up since %s',
      $self->human_timeticks($self->{uptime}));
  $self->set_thresholds(warning => '15:', critical => '5:');
  $self->add_message($self->check_thresholds($self->{uptime} / 60));
  $self->add_perfdata(
      label => 'uptime',
      value => $self->{uptime} / 60,
      places => 0,
  );
}

