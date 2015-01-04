package Classes::UPNP::AVM::FritzBox7390::Component::InterfaceSubsystem;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces/) {
    $self->{ifDescr} = "WAN";
    my $service = (grep { $_->{serviceId} =~ /WANIPConn1/ } @{$self->get_variable('services')})[0];
    $self->{ExternalIPAddress} = SOAP::Lite
      -> proxy($service->{controlURL})
      -> uri($service->{serviceType})
      -> GetExternalIPAddress()
      -> result;
    $self->{ConnectionStatus} = SOAP::Lite
      -> proxy($service->{controlURL})
      -> uri($service->{serviceType})
      -> GetStatusInfo()
      -> valueof("//GetStatusInfoResponse/NewConnectionStatus");;
    $service = (grep { $_->{serviceId} =~ /WANCommonIFC1/ } @{$self->get_variable('services')})[0];
    $self->{PhysicalLinkStatus} = SOAP::Lite
      -> proxy($service->{controlURL})
      -> uri($service->{serviceType})
      -> GetCommonLinkProperties()
      -> valueof("//GetCommonLinkPropertiesResponse/NewPhysicalLinkStatus");
    $self->{Layer1UpstreamMaxBitRate} = SOAP::Lite
      -> proxy($service->{controlURL})
      -> uri($service->{serviceType})
      -> GetCommonLinkProperties()
      -> valueof("//GetCommonLinkPropertiesResponse/NewLayer1UpstreamMaxBitRate");
    $self->{Layer1DownstreamMaxBitRate} = SOAP::Lite
      -> proxy($service->{controlURL})
      -> uri($service->{serviceType})
      -> GetCommonLinkProperties()
      -> valueof("//GetCommonLinkPropertiesResponse/NewLayer1DownstreamMaxBitRate");
    $self->{TotalBytesSent} = SOAP::Lite
      -> proxy($service->{controlURL})
      -> uri($service->{serviceType})
      -> GetTotalBytesSent()
      -> result;
    $self->{TotalBytesReceived} = SOAP::Lite
      -> proxy($service->{controlURL})
      -> uri($service->{serviceType})
      -> GetTotalBytesReceived()
      -> result;
    if ($self->mode =~ /device::interfaces::usage/) {
      $self->valdiff({name => $self->{ifDescr}}, qw(TotalBytesSent TotalBytesReceived));
      $self->{inputUtilization} = $self->{delta_TotalBytesReceived} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{Layer1DownstreamMaxBitRate});
      $self->{outputUtilization} = $self->{delta_TotalBytesSent} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{Layer1UpstreamMaxBitRate});
      $self->{inputRate} = $self->{delta_TotalBytesReceived} / $self->{delta_timestamp};
      $self->{outputRate} = $self->{delta_TotalBytesSent} / $self->{delta_timestamp};
      my $factor = 1/8; # default Bits
      if ($self->opts->units) {
        if ($self->opts->units eq "GB") {
          $factor = 1024 * 1024 * 1024;
        } elsif ($self->opts->units eq "MB") {
          $factor = 1024 * 1024;
        } elsif ($self->opts->units eq "KB") {
          $factor = 1024;
        } elsif ($self->opts->units eq "GBi") {
          $factor = 1024 * 1024 * 1024 / 8;
        } elsif ($self->opts->units eq "MBi") {
          $factor = 1024 * 1024 / 8;
        } elsif ($self->opts->units eq "KBi") {
          $factor = 1024 / 8;
        } elsif ($self->opts->units eq "B") {
          $factor = 1;
        } elsif ($self->opts->units eq "Bit") {
          $factor = 1/8;
        }
      }
      $self->{inputRate} /= $factor;
      $self->{outputRate} /= $factor;
      $self->{Layer1DownstreamMaxKBRate} =
          ($self->{Layer1DownstreamMaxBitRate} / 8) / 1024;
      $self->{Layer1UpstreamMaxKBRate} =
          ($self->{Layer1UpstreamMaxBitRate} / 8) / 1024;
    } elsif ($self->mode =~ /device::interfaces::operstatus/) {
    } elsif ($self->mode =~ /device::interfaces::list/) {
    } else {
      $self->no_such_mode();
    }
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking interfaces');
  if ($self->mode =~ /device::interfaces::usage/) {
    $self->add_info(sprintf 'interface %s usage is in:%.2f%% (%s) out:%.2f%% (%s)',
        $self->{ifDescr},
        $self->{inputUtilization},
        sprintf("%.2f%s/s", $self->{inputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')),
        $self->{outputUtilization},
        sprintf("%.2f%s/s", $self->{outputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')));
    $self->set_thresholds(warning => 80, critical => 90);
    my $in = $self->check_thresholds($self->{inputUtilization});
    my $out = $self->check_thresholds($self->{outputUtilization});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization},
        uom => '%',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization},
        uom => '%',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units,
        thresholds => 0,
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units,
        thresholds => 0,
    );
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
    $self->add_info(sprintf 'interface %s%s status is %s',
        $self->{ifDescr}, 
        $self->{ExternalIPAddress} ? " (".$self->{ExternalIPAddress}.")" : "",
        $self->{ConnectionStatus});
    if ($self->{ConnectionStatus} eq "Connected") {
      $self->add_ok();
    } else {
      $self->add_critical();
    }
  } elsif ($self->mode =~ /device::interfaces::list/) {
    printf "%s\n", $self->{ifDescr};
    $self->add_ok("have fun");
  }
}

