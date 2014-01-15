package NWC::SGOS::Component::ConnectionSubsystem;
our @ISA = qw(NWC::SGOS);

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
  foreach (qw(sgProxyHttpResponseTimeAll sgProxyHttpResponseFirstByte
      sgProxyHttpResponseByteRate sgProxyHttpResponseSize
      sgProxyHttpClientConnections sgProxyHttpClientConnectionsActive
      sgProxyHttpClientConnectionsIdle
      sgProxyHttpServerConnections sgProxyHttpServerConnectionsActive
      sgProxyHttpServerConnectionsIdle)) {
    $self->{$_} = $self->get_snmp_object('BLUECOAT-SG-PROXY-MIB', $_, 0);
  }
  $self->{sgProxyHttpResponseTimeAll} /= 1000;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking connections');
  if ($self->mode =~ /device::connections::check/) {
    my $info = sprintf 'average service time for http requests is %.5fs',
        $self->{sgProxyHttpResponseTimeAll};
    $self->add_info($info);
    $self->set_thresholds(warning => 5, critical => 10);
    $self->add_message($self->check_thresholds($self->{sgProxyHttpResponseTimeAll}), $info);
    $self->add_perfdata(
        label => 'http_response_time',
        value => $self->{sgProxyHttpResponseTimeAll},
        places => 5,
        uom => 's',
        warning => $self->{warning},
        critical => $self->{critical}
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
      my $info = sprintf '%d %s connections %s', $self->{$_->[2]}, $_->[0], $_->[1];
      $self->add_info($info);
      $self->set_thresholds(warning => 5000, critical => 10000);
      $self->add_message($self->check_thresholds($self->{$_->[2]}), $info);
      $self->add_perfdata(
          label => $_->[0].'_connections_'.$_->[1],
          value => $self->{$_->[2]},
          warning => $self->{warning},
          critical => $self->{critical}
      );
    }
  }
}

sub dump {
  my $self = shift;
  printf "[CONNECTIONS]\n";
  foreach (qw(sgProxyHttpResponseTimeAll sgProxyHttpResponseFirstByte
      sgProxyHttpResponseByteRate sgProxyHttpResponseSize
      sgProxyHttpClientConnections sgProxyHttpClientConnectionsActive
      sgProxyHttpClientConnectionsIdle
      sgProxyHttpServerConnections sgProxyHttpServerConnectionsActive
      sgProxyHttpServerConnectionsIdle)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

