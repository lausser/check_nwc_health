package Classes::F5::F5BIGIP::Component::ConnectionSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::users::count/) {
    $self->get_snmp_objects('F5-BIGIP-SYSTEM-MIB', (qw(sysStatClientCurConns sysStatServerCurConns)));
  } elsif ($self->mode =~ /device::connections::count/) {
    $self->get_snmp_objects('F5-BIGIP-APM-MIB', (qw(
        apmAccessStatTotalSessions apmAccessStatCurrentActiveSessions
	apmGlobalConnectivityStatTotConns apmGlobalConnectivityStatCurConns
    )));
  }
}

sub check {
  my $self = shift;
  if ($self->mode =~ /device::users::count/) {
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
  } elsif ($self->mode =~ /device::connections::count/) {
    # schwellwerte aus https://support.f5.com/csp/article/K15032
    $self->set_thresholds(metric => 'apm_access_sessions',
        warning => 2000, critical => 2500);
    $self->add_info(sprintf '%d current access sessions',
        $self->{apmAccessStatCurrentActiveSessions});
    $self->add_message($self->check_thresholds(
        metric => 'apm_access_sessions',
        value => $self->{apmAccessStatCurrentActiveSessions}
    ));
    $self->add_perfdata(
        label => 'apm_access_sessions',
        value => $self->{apmAccessStatCurrentActiveSessions},
    );
    $self->set_thresholds(metric => 'apm_ccu_sessions',
        warning => 400, critical => 500);
    $self->add_info(sprintf '%d current connectivity sessions',
        $self->{apmGlobalConnectivityStatCurConns});
    $self->add_message($self->check_thresholds(
        metric => 'apm_ccu_sessions',
        value => $self->{apmGlobalConnectivityStatCurConns}
    ));
    $self->add_perfdata(
        label => 'apm_ccu_sessions',
        value => $self->{apmGlobalConnectivityStatCurConns},
    );
  }
}

