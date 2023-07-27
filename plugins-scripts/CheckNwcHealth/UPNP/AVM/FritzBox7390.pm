package CheckNwcHealth::UPNP::AVM::FritzBox7390;
our @ISA = qw(CheckNwcHealth::UPNP::AVM);
use strict;

{
  our $sid = undef;
}

sub sid : lvalue {
  my ($self) = @_;
  $CheckNwcHealth::UPNP::AVM::FritzBox7390::sid;
}

sub init {
  my ($self) = @_;
  foreach my $module (qw(HTML::TreeBuilder LWP::UserAgent Encode Digest::MD5 JSON)) {
    if (! eval "require $module") {
      $self->add_unknown("could not find $module module");
    }
  }
  if (! $self->check_messages()) {
    if ($self->mode =~ /device::hardware::health/) {
      $self->login();
      $self->analyze_environmental_subsystem();
      $self->check_environmental_subsystem();
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->login();
      $self->analyze_cpu_subsystem();
      $self->check_cpu_subsystem();
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->login();
      $self->analyze_mem_subsystem();
      $self->check_mem_subsystem();
    } elsif ($self->mode =~ /device::interfaces/) {
      $self->analyze_and_check_interface_subsystem("CheckNwcHealth::UPNP::AVM::FritzBox7390::Component::InterfaceSubsystem");
    } elsif ($self->mode =~ /device::smarthome/) {
      $self->login();
      $self->analyze_and_check_smarthome_subsystem("CheckNwcHealth::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem");
    } else {
      $self->no_such_mode();
    }
    $self->logout();
  }
}

sub login {
  my ($self) = @_;
  my $ua = LWP::UserAgent->new;
  my $loginurl = sprintf "http://%s/login_sid.lua", $self->opts->hostname;
  my $resp = $ua->get($loginurl);
  my $content = $resp->content();
  my $challenge = ($content =~ /<Challenge>(.*?)<\/Challenge>/ && $1);
  my $input = $challenge . '-' . $self->opts->community;
  Encode::from_to($input, 'ascii', 'utf16le');
  my $challengeresponse = $challenge . '-' . lc(Digest::MD5::md5_hex($input));
  $resp = HTTP::Request->new(POST => $loginurl);
  $resp->content_type("application/x-www-form-urlencoded");
  my $login = "response=$challengeresponse";
  if ($self->opts->username) {
      $login .= "&username=" . $self->opts->username;
  }
  $resp->content($login);
  my $loginresp = $ua->request($resp);
  $content = $loginresp->content();
  $self->sid() = ($content =~ /<SID>(.*?)<\/SID>/ && $1);
  if (! $loginresp->is_success() || ! $self->sid() || $self->sid() =~ /^0+$/) {
    $self->add_critical($loginresp->status_line());
  } else {
    $self->debug("logged in with sid ".$self->sid());
  }
}

sub logout {
  my ($self) = @_;
  return if ! $self->sid();
  my $ua = LWP::UserAgent->new;
  my $loginurl = sprintf "http://%s/login_sid.lua", $self->opts->hostname;
  my $resp = HTTP::Request->new(POST => $loginurl);
  $resp->content_type("application/x-www-form-urlencoded");
  my $logout = "sid=".$self->sid()."&security:command/logout=1";
  $resp->content($logout);
  my $logoutresp = $ua->request($resp);
  $self->sid() = undef;
  $self->debug("logged out");
}

sub DESTROY {
  my ($self) = @_;
  $self->logout();
}

sub http_get {
  my ($self, $page) = @_;
  my $ua = LWP::UserAgent->new;
  if ($page =~ /\?/) {
    $page .= "&sid=".$self->sid();
  } else {
    $page .= "?sid=".$self->sid();
  }
  my $url = sprintf "http://%s/%s", $self->opts->hostname, $page;
  $self->debug("http get ".$url);
  my $resp = $ua->get($url);
  if (! $resp->is_success()) {
    $self->add_critical($resp->status_line());
  } else {
  }
  return $resp->content();
}

sub analyze_cpu_subsystem {
  my ($self) = @_;
  my $html = $self->http_get('system/ecostat.lua');
  if ($html =~ /uiSubmitLogin/) {
    $self->add_critical("wrong login");
    $self->{cpu_usage} = 0;
  } elsif ($html =~ /StatCPU/) {
    my $cpu = (grep /StatCPU/, split(/\n/, $html))[0];
    my @cpu = ($cpu =~ /= "(.*?)"/ && split(/,/, $1));
    $self->{cpu_usage} = $cpu[0];
  } elsif ($html =~ /uiViewCpu/) {
    $html =~ /Query1 = "(.*?)"/;
    $self->{cpu_usage} = (split(",", $1))[0];
  }
}

sub analyze_mem_subsystem {
  my ($self) = @_;
  my $html = $self->http_get('system/ecostat.lua');
  if ($html =~ /uiSubmitLogin/) {
    $self->add_critical("wrong login");
    $self->{ram_used} = 0;
  } elsif ($html =~ /StatRAMCacheUsed/) {
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
  } elsif ($html =~ /uiViewRamValue/) {
    $html =~ /Query1 ="(.*?)"/;
    $self->{ram_free} = (split(",", $1))[0];
    $html =~ /Query2 ="(.*?)"/;
    $self->{ram_dynamic} = (split(",", $1))[0];
    $html =~ /Query3 ="(.*?)"/;
    $self->{ram_fix} = (split(",", $1))[0];
    $self->{ram_used} = $self->{ram_fix} + $self->{ram_dynamic};
  }
}

sub check_cpu_subsystem {
  my ($self) = @_;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{cpu_usage});
  $self->set_thresholds(warning => 40, critical => 60);
  $self->add_message($self->check_thresholds($self->{cpu_usage}), $self->{info});
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub check_mem_subsystem {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%', $self->{ram_used});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{ram_used}), $self->{info});
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{ram_used},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}





