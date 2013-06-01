package UPNP::AVM::FritzBox7390;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(UPNP::AVM);

sub init {
  my $self = shift;
  foreach my $module (qw(HTML::TreeBuilder LWP::UserAgent Encode Digest::MD5 JSON)) {
    if (! eval "require $module") {
      $self->add_message(UNKNOWN,
          "could not find $module module");
    }
  }
  $self->{sid} = undef;
  $self->{components} = {
    interface_subsystem => undef,
    smarthome_subsystem => undef,
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
    } elsif ($self->mode =~ /device::smarthome/) {
      $self->analyze_smarthome_subsystem();
      $self->check_smarthome_subsystem();
    }
  }
}

sub http_get {
  my $self = shift;
  my $page = shift;
  my $ua = LWP::UserAgent->new;
  if (! $self->{sid}) {
    my $loginurl = sprintf "http://%s/login_sid.lua", $self->opts->hostname;
    my $resp = $ua->get($loginurl);
    my $content = $resp->content();
    my $challenge = ($content =~ /<Challenge>(.*?)<\/Challenge>/ && $1);
    my $input = $challenge . '-' . $self->opts->community;
    Encode::from_to($input, 'ascii', 'utf16le');
    my $challengeresponse = $challenge . '-' . lc(Digest::MD5::md5_hex($input));
    $resp = HTTP::Request->new(POST => $loginurl);
    $resp->content_type("application/x-www-form-urlencoded");
    $resp->content("response=$challengeresponse");
    my $loginresp = $ua->request($resp);
    $content = $loginresp->content();
    $self->{sid} = ($content =~ /<SID>(.*?)<\/SID>/ && $1);
    if (! $loginresp->is_success()) {
      $self->add_message(CRITICAL, $loginresp->status_line());
    }
  }
  if ($page =~ /\?/) {
    $page .= "&sid=$self->{sid}";
  } else {
    $page .= "?sid=$self->{sid}";
  }
  my $ecourl = sprintf "http://%s/%s", $self->opts->hostname, $page;
  my $resp = $ua->get($ecourl);
  if (! $resp->is_success()) {
    $self->add_message(CRITICAL, $resp->status_line());
  }
  return $resp->content();
}

sub analyze_smarthome_subsystem {
  my $self = shift;
  $self->{components}->{smarthome_subsystem} =
      UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem->new();
}

sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      UPNP::AVM::FritzBox7390::Component::InterfaceSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  my $html = $self->http_get('system/ecostat.lua');
  my $cpu = (grep /StatCPU/, split(/\n/, $html))[0];
  my @cpu = ($cpu =~ /= "(.*?)"/ && split(/,/, $1));
  $self->{cpu_usage} = $cpu[0];
}

sub analyze_mem_subsystem {
  my $self = shift;
  my $html = $self->http_get('system/ecostat.lua');
  my $ramcacheused = (grep /StatRAMCacheUsed/, split(/\n/, $html))[0];
  my @ramcacheused = ($ramcacheused =~ /= "(.*?)"/ && split(/,/, $1));
  $self->{ram_cache_used} = $ramcacheused[0];
  my $ramphysfree = (grep /StatRAMPhysFree/, split(/\n/, $html))[0];
  my @ramphysfree = ($ramphysfree =~ /= "(.*?)"/ && split(/,/, $1));
  $self->{ram_phys_free} = $ramphysfree[0];
  my $ramstrictlyused = (grep /StatRAMStrictlyUsed/, split(/\n/, $html))[0];
  my @ramstrictlyused = ($ramstrictlyused =~ /= "(.*?)"/ && split(/,/, $1));
  $self->{ram_strictly_used} = $ramstrictlyused[0];
  $self->{ram_used} = $self->{ram_strictly_used} + $self->{ram_cache_used};
}

sub check_smarthome_subsystem {
  my $self = shift;
  $self->{components}->{smarthome_subsystem}->check();
  $self->{components}->{smarthome_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem}->check();
  $self->{components}->{interface_subsystem}->dump()
      if $self->opts->verbose >= 2;
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

sub check_mem_subsystem {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('m', undef);
  my $info = sprintf 'memory usage is %.2f%%', $self->{ram_used};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{ram_used}), $info);
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{ram_used},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}





