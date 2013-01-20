package UPNP::AVM::FritzBox7390;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(UPNP::AVM);

sub init {
  my $self = shift;
  $self->{components} = {
      interface_subsystem => undef,
  };
  if (! $self->check_messages()) {
    ##$self->set_serial();
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_environmental_subsystem();
      #$self->auto_blacklist();
      $self->check_environmental_subsystem();
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_cpu_subsystem();
      #$self->auto_blacklist();
      $self->check_cpu_subsystem();
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_mem_subsystem();
      #$self->auto_blacklist();
      $self->check_mem_subsystem();
    } elsif ($self->mode =~ /device::interfaces/) {
      $self->analyze_interface_subsystem();
      $self->check_interface_subsystem();
    }
  }
}

sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      UPNP::AVM::FritzBox7390::Component::InterfaceSubsystem->new();
}

sub check_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem}->check();
  $self->{components}->{interface_subsystem}->dump()
      if $self->opts->verbose >= 2;
}


package UPNP::AVM::FritzBox7390::Component::InterfaceSubsystem;
our @ISA = qw(NWC::IFMIB);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    interface_cache => {},
    interfaces => [],
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
  if ($self->mode =~ /device::interfaces::list/) {
    $self->update_interface_cache(1);
    foreach my $ifidxdescr (keys %{$self->{interface_cache}}) {
      my ($ifIndex, $ifDescr) = split('#', $ifidxdescr, 2);
      push(@{$self->{interfaces}},
          NWC::IFMIB::Component::InterfaceSubsystem::Interface->new(
              #ifIndex => $self->{interface_cache}->{$ifDescr},
              #ifDescr => $ifDescr,
              ifIndex => $ifIndex,
              ifDescr => $ifDescr,
          ));
    }
  } else {
    $self->{ifDescr} = "WAN";
    $self->{ExternalIPAddress} = SOAP::Lite
      -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
      -> uri('urn:schemas-upnp-org:service:WANIPConnection:1')
      -> GetExternalIPAddress()
      -> result;
    $self->{ConnectionStatus} = SOAP::Lite
      -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
      -> uri('urn:schemas-upnp-org:service:WANIPConnection:1')
      -> GetStatusInfo()
      -> valueof("//GetStatusInfoResponse/NewConnectionStatus");;
    $self->{PhysicalLinkStatus} = SOAP::Lite
      -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
      -> uri('urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1')
      -> GetCommonLinkProperties()
      -> valueof("//GetCommonLinkPropertiesResponse/NewPhysicalLinkStatus");
    $self->{Layer1UpstreamMaxBitRate} = SOAP::Lite
      -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
      -> uri('urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1')
      -> GetCommonLinkProperties()
      -> valueof("//GetCommonLinkPropertiesResponse/NewLayer1UpstreamMaxBitRate");
    $self->{Layer1DownstreamMaxBitRate} = SOAP::Lite
      -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
      -> uri('urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1')
      -> GetCommonLinkProperties()
      -> valueof("//GetCommonLinkPropertiesResponse/NewLayer1DownstreamMaxBitRate");
    $self->{TotalBytesSent} = SOAP::Lite
      -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
      -> uri('urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1')
      -> GetTotalBytesSent()
      -> result;
    $self->{TotalBytesReceived} = SOAP::Lite
      -> proxy('http://192.168.1.1:49000/upnp/control/WANCommonIFC1')
      -> uri('urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1')
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
    }
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking interfaces');
  if ($self->mode =~ /device::interfaces::usage/) {
    my $info = sprintf 'interface %s usage is in:%.2f%% (%s) out:%.2f%% (%s)',
        $self->{ifDescr},
        $self->{inputUtilization},
        sprintf("%.2f%s/s", $self->{inputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')),
        $self->{outputUtilization},
        sprintf("%.2f%s/s", $self->{outputRate},
            ($self->opts->units ? $self->opts->units : 'Bits'));
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    my $in = $self->check_thresholds($self->{inputUtilization});
    my $out = $self->check_thresholds($self->{outputUtilization});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level, $info);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units,
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units,
    );
  }
  $self->dump()
      if $self->opts->verbose >= 2;
}

sub dump {
  my $self = shift;
  foreach (qw(TotalBytesSent TotalBytesReceived Layer1DownstreamMaxBitRate Layer1UpstreamMaxBitRate)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}

