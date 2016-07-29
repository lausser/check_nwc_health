package Classes::F5::F5BIGIP::Component::ConnectionSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('F5-BIGIP-SYSTEM-MIB', (qw(sysStatClientCurConns sysStatServerCurConns)));
}

sub check {
  my $self = shift;
  $self->set_thresholds(warning => 500000, critical => 750000);
  $self->add_info(sprintf '%d client connections in use', $self->{sysStatClientCurConns});
  $self->add_message($self->check_thresholds(metric => 'client_cur_conns', value => $self->{sysStatClientCurConns}));
  $self->add_perfdata(
      label => 'client_cur_conns',
      value => $self->{sysStatClientCurConns},
  );
  $self->add_info(sprintf '%d server connections in use', $self->{sysStatServerCurConns});
  $self->add_message($self->check_thresholds(metric => 'server_cur_conns', value => $self->{sysStatServerCurConns}));
  $self->add_perfdata(
      label => 'server_cur_conns',
      value => $self->{sysStatServerCurConns},
  );
}

