package Classes::SGOS::Component::ConnectionSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('BLUECOAT-SG-PROXY-MIB', (qw(sgProxyHttpResponseTimeAll
      sgProxyHttpResponseFirstByte
      sgProxyHttpResponseByteRate sgProxyHttpResponseSize
      sgProxyHttpClientConnections sgProxyHttpClientConnectionsActive
      sgProxyHttpClientConnectionsIdle
      sgProxyHttpServerConnections sgProxyHttpServerConnectionsActive
      sgProxyHttpServerConnectionsIdle)));
  $self->{sgProxyHttpResponseTimeAll} /= 1000;
}

sub check {
  my ($self) = @_;
  $self->add_info('checking connections');
  if ($self->mode =~ /device::connections::check/) {
    $self->add_info(sprintf 'average service time for http requests is %.5fs',
        $self->{sgProxyHttpResponseTimeAll});
    $self->set_thresholds(warning => 5, critical => 10);
    $self->add_message($self->check_thresholds($self->{sgProxyHttpResponseTimeAll}));
    $self->add_perfdata(
        label => 'http_response_time',
        value => $self->{sgProxyHttpResponseTimeAll},
        places => 5,
        uom => 's',
    );
  } elsif ($self->mode =~ /device::.*?::count/) {
    my $details = [
        ['client', 'total', 'sgProxyHttpClientConnections'],
        ['client', 'active', 'sgProxyHttpClientConnectionsActive'],
        ['client', 'idle', 'sgProxyHttpClientConnectionsIdle'],
        ['server', 'total', 'sgProxyHttpServerConnections'],
        ['server', 'active', 'sgProxyHttpServerConnectionsActive'],
        ['server', 'idle', 'sgProxyHttpServerConnectionsIdle'],
    ];
    my @selected;
    # --name client --name2 idle
    if (! $self->opts->name) {
      @selected = @{$details};
    } elsif (! $self->opts->name2) {
      @selected = grep { $_->[0] eq $self->opts->name } @{$details};
    } else {
      @selected = grep { $_->[0] eq $self->opts->name && $_->[1] eq $self->opts->name2 } @{$details};
    }
    foreach (@selected) {
      my $label = $_->[0].'_connections_'.$_->[1];
      $self->add_info(sprintf '%d %s connections %s', $self->{$_->[2]}, $_->[0], $_->[1]);
      $self->set_thresholds(metric => $label,
          warning => 5000, critical => 10000);
      $self->add_message($self->check_thresholds(metric => $label,
          value => $self->{$_->[2]}));
      $self->add_perfdata(
          label => $label,
          value => $self->{$_->[2]},
      );
    }
  }
}


