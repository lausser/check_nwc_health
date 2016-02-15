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
      $self->{delta_ifInBits} = $self->{delta_TotalBytesReceived} * 8;
      $self->{delta_ifOutBits} = $self->{delta_TotalBytesSent} * 8;
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->{Layer1DownstreamMaxBitRate});
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->{Layer1UpstreamMaxBitRate});
      $self->{maxInputRate} = $self->{Layer1DownstreamMaxBitRate};
      $self->{maxOutputRate} = $self->{Layer1UpstreamMaxBitRate};
      $self->{inputRate} = $self->{delta_ifInBits} / $self->{delta_timestamp};
      $self->{outputRate} = $self->{delta_ifOutBits} / $self->{delta_timestamp};
      $self->override_opt("units", "bit") if ! $self->opts->units;
      $self->{inputRate} /= $self->number_of_bits($self->opts->units);
      $self->{outputRate} /= $self->number_of_bits($self->opts->units);
      $self->{maxInputRate} /= $self->number_of_bits($self->opts->units);
      $self->{maxOutputRate} /= $self->number_of_bits($self->opts->units);
      if ($self->{ConnectionStatus} ne "Connected") {
        $self->{inputUtilization} = 0;
        $self->{outputUtilization} = 0;
        $self->{inputRate} = 0;
        $self->{outputRate} = 0;
        $self->{maxInputRate} = 0;
        $self->{maxOutputRate} = 0;
      }
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
        sprintf("%.2f%s/s", $self->{inputRate}, $self->opts->units),
        $self->{outputUtilization},
        sprintf("%.2f%s/s", $self->{outputRate}, $self->opts->units));
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
        warning => 80,
        critical => 90
    );
    my $in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
        warning => 80,
        critical => 90
    );
    my $out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization}
    );
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

    my ($inwarning, $incritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_traffic_in',
        warning => $self->{maxInputRate} / 100 * $inwarning,
        critical => $self->{maxInputRate} / 100 * $incritical
    );
    $self->ade_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxInputRate},
    );
    my ($outwarning, $outcritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_traffic_out',
        warning => $self->{maxOutputRate} / 100 * $outwarning,
        critical => $self->{maxOutputRate} / 100 * $outcritical,
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxOutputRate},
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

