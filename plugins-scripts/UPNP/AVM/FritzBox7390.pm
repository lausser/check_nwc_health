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

sub analyze_cpu_subsystem {
  my $self = shift;
  require LWP::UserAgent;
  require Encode;
  require Digest::MD5;
  my $loginurl = sprintf "http://%s/login_sid.lua", $self->opts->hostname;
  my $ecourl = sprintf "http://%s/system/ecostat.lua", $self->opts->hostname;
  my $ua = LWP::UserAgent->new;
  #printf "login %s\n", $loginurl;
  my $resp = $ua->get($loginurl);
  my $content = $resp->content();
  #  <SessionInfo>
  #  <iswriteaccess>0</iswriteaccess>
  #  <SID>0000000000000000</SID>
  #  <Challenge>eb6422fa</Challenge>
  #  </SessionInfo>
  my $challenge = ($content =~ /<Challenge>(.*?)<\/Challenge>/ && $1);
  #printf "chall %s\n", $challenge;
  my $input = $challenge . '-' . $self->opts->community;
  Encode::from_to($input, 'ascii', 'utf16le');
  my $challengeresponse = $challenge . '-' . lc(Digest::MD5::md5_hex($input));
  #printf "chare %s\n", $challengeresponse;
  $resp = HTTP::Request->new(POST => $loginurl);
  $resp->content_type("application/x-www-form-urlencoded");
  $resp->content("response=$challengeresponse");
  my $loginresp = $ua->request($resp);
  $content = $loginresp->content();
  my $sid = ($content =~ /<SID>(.*?)<\/SID>/ && $1);
  #printf "sid %s\n", $sid;
  if (! $loginresp->is_success()) {
    $self->add_message(CRITICAL, $loginresp->status_line());
  }
  $resp = $ua->post($ecourl, [
      'sid' => [ undef, undef, 'Content' => "$sid", ],
  ]);
  if (! $resp->is_success()) {
    $self->add_message(CRITICAL, $resp->status_line());
  }
  my $html = $resp->as_string();
  my $cpu = (grep /StatCPU/, split(/\n/, $html))[0];
  my @cpu = ($cpu =~ /= "(.*?)"/ && split(/,/, $1));
  $self->{cpu_usage} = $cpu[0];
}

sub check_cpu_subsystem {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('c', undef);
  my $info = sprintf 'cpu usage is %.2f%%', $self->{cpu_usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 40, critical => 60);
  $self->add_message($self->check_thresholds($self->{cpu_usage}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
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
      $self->{Layer1DownstreamMaxKBRate} =
          ($self->{Layer1DownstreamMaxBitRate} / 8) / 1024;
      $self->{Layer1UpstreamMaxKBRate} =
          ($self->{Layer1UpstreamMaxBitRate} / 8) / 1024;
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
}

sub dump {
  my $self = shift;
  printf "[WAN]\n";
  foreach (qw(TotalBytesSent TotalBytesReceived Layer1DownstreamMaxBitRate Layer1UpstreamMaxBitRate Layer1DownstreamMaxKBRate Layer1UpstreamMaxKBRate)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}

