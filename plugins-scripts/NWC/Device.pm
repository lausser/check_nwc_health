package NWC::Device;

use strict;
use IO::File;
use File::Basename;
use Digest::MD5  qw(md5_hex);
use Errno;
use AutoLoader;
our $AUTOLOAD;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

{
  our $mode = undef;
  our $plugin = undef;
  our $blacklist = undef;
  our $session = undef;
  our $rawdata = {};
  our $info = [];
  our $extendedinfo = [];
  our $summary = [];
  our $statefilesdir = '/var/tmp/check_nwc_health';
  our $oidtrace = [];
  our $uptime = 0;
}

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    productname => 'unknown',
  };
  bless $self, $class;
  if (! ($self->opts->hostname || $self->opts->snmpwalk)) {
    die "wie jetzt??!?!";
  } else {
    if ($self->opts->servertype && $self->opts->servertype eq 'linuxlocal') {
    } elsif ($self->opts->port && $self->opts->port == 49000) {
      $self->{productname} = 'upnp';
    } else {
      $self->check_snmp_and_model();
    }
    if ($self->opts->servertype) {
      $self->{productname} = 'cisco' if $self->opts->servertype eq 'cisco';
      $self->{productname} = 'huawei' if $self->opts->servertype eq 'huawei';
      $self->{productname} = 'hp' if $self->opts->servertype eq 'hp';
      $self->{productname} = 'brocade' if $self->opts->servertype eq 'brocade';
      $self->{productname} = 'netscreen' if $self->opts->servertype eq 'netscreen';
      $self->{productname} = 'linuxlocal' if $self->opts->servertype eq 'linuxlocal';
      $self->{productname} = 'procurve' if $self->opts->servertype eq 'procurve';
      $self->{productname} = 'bluecoat' if $self->opts->servertype eq 'bluecoat';
      $self->{productname} = 'checkpoint' if $self->opts->servertype eq 'checkpoint';
      $self->{productname} = 'ifmib' if $self->opts->servertype eq 'ifmib';
    }
    if (! $NWC::Device::plugin->check_messages()) {
      if ($self->opts->verbose && $self->opts->verbose) {
        printf "I am a %s\n", $self->{productname};
      }
      # Brocade 4100 SilkWorm also sold as IBM 2005-B32 & EMC DS-4100
      # Brocade 4900 Switch also sold as IBM 2005-B64(3) & EMC DS4900B
      # Brocade M4700 (McData name Sphereon 4700) also sold as IBM 2026-432 & EMC DS-4700M
      if ($self->{productname} =~ /Cisco/i) {
        bless $self, 'NWC::Cisco';
        $self->debug('using NWC::Cisco');
      } elsif ($self->{productname} =~ /fujitsu intelligent blade panel 30\/12/i) {
        bless $self, 'NWC::Cisco';
        $self->debug('using NWC::Cisco');
      } elsif ($self->{productname} =~ /Nortel/i) {
        bless $self, 'NWC::Nortel';
        $self->debug('using NWC::Nortel');
      } elsif ($self->{productname} =~ /AT-GS/i) {
        bless $self, 'NWC::AlliedTelesyn';
        $self->debug('using NWC::AlliedTelesyn');
      } elsif ($self->{productname} =~ /AT-\d+GB/i) {
        bless $self, 'NWC::AlliedTelesyn';
        $self->debug('using NWC::AlliedTelesyn');
      } elsif ($self->{productname} =~ /Allied Telesyn Ethernet Switch/i) {
        bless $self, 'NWC::AlliedTelesyn';
        $self->debug('using NWC::AlliedTelesyn');
      } elsif ($self->{productname} =~ /DS_4100/i) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } elsif ($self->{productname} =~ /Connectrix DS_4900B/i) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS.*4700M/i) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS-24M2/i) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } elsif ($self->{productname} =~ /Brocade.*ICX/i) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } elsif ($self->{productname} =~ /Fibre Channel Switch/i) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } elsif ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
        # Juniper Networks,Inc,MAG-4610,7.2R10
        bless $self, 'NWC::Juniper';
        $self->debug('using NWC::Juniper');
      } elsif ($self->{productname} =~ /NetScreen/i) {
        bless $self, 'NWC::Juniper';
        $self->debug('using NWC::Juniper');
      } elsif ($self->{productname} =~ /^(GS|FS)/i) {
        bless $self, 'NWC::Juniper';
        $self->debug('using NWC::Juniper');
      } elsif ($self->{productname} =~ /SecureOS/i) {
        bless $self, 'NWC::SecureOS';
        $self->debug('using NWC::SecureOS');
      } elsif ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i) {
        bless $self, 'NWC::F5';
        $self->debug('using NWC::F5');
      } elsif ($self->{productname} =~ /Procurve/i) {
        bless $self, 'NWC::HP';
        $self->debug('using NWC::HP');
      } elsif ($self->{productname} =~ /(cpx86_64)|(Check\s*Point)|(Linux.*\dcp )/i) {
        bless $self, 'NWC::CheckPoint';
        $self->debug('using NWC::CheckPoint');
      } elsif ($self->{productname} =~ /Blue\s*Coat/i) {
        bless $self, 'NWC::Bluecoat';
        $self->debug('using NWC::Bluecoat');
      } elsif ($self->{productname} =~ /Foundry/i) {
        bless $self, 'NWC::Foundry';
        $self->debug('using NWC::Foundry');
      } elsif ($self->{productname} =~ /linuxlocal/i) {
        bless $self, 'Server::Linux';
        $self->debug('using Server::Linux');
      } elsif ($self->{productname} =~ /upnp/i) {
        bless $self, 'UPNP';
        $self->debug('using UPNP');
      } elsif ($self->{productname} eq "ifmib") {
        bless $self, 'NWC::Generic';
        $self->debug('using NWC::Generic');
      } elsif ($self->get_snmp_object('MIB-II', 'sysObjectID', 0) eq $NWC::Device::mib_ids->{'SW-MIB'}) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } else {
        my $sysobj = $self->get_snmp_object('MIB-II', 'sysObjectID', 0);
        if ($sysobj && exists $NWC::Device::discover_ids->{$sysobj}) {
          bless $self, $NWC::Device::discover_ids->{$sysobj};
          $self->debug('using '.$NWC::Device::discover_ids->{$sysobj});
        } else {
          $self->add_message(CRITICAL,
              sprintf('unknown device%s', $self->{productname} eq 'unknown' ?
                  '' : '('.$self->{productname}.')'));
        }
      }
    }
  }
  $self->{method} = 'snmp';
  if ($self->opts->blacklist &&
      -f $self->opts->blacklist) {
    $self->opts->blacklist = do {
        local (@ARGV, $/) = $self->opts->blacklist; <> };
  }
  $NWC::Device::statefilesdir = $self->opts->statefilesdir;
  return $self;
}

sub init {
  my $self = shift;
  if ($self->mode =~ /device::walk/) {
    my @trees = ();
    my $name = $0;
    $name =~ s/.*\///g;
    $name = sprintf "/tmp/snmpwalk_%s_%s", $name, $self->opts->hostname;
    if ($self->opts->oids) {
      # create pid filename
      # already running?;x
      @trees = split(",", $self->opts->oids);

    } elsif ($self->can("trees")) {
      @trees = $self->trees;
    }
    if ($self->opts->snmpdump) {
      $name = $self->opts->snmpdump;
    }
    if (defined $self->opts->offline) {
      $self->{pidfile} = $name.".pid";
      if (! $self->check_pidfile()) {
        $self->trace("Exiting because another walk is already running");
        printf STDERR "Exiting because another walk is already running\n";
        exit 3;
      }
      $self->write_pidfile();
      my $timedout = 0;
      my $snmpwalkpid = 0;
      $SIG{'ALRM'} = sub {
        $timedout = 1;
        printf "UNKNOWN - check_nwc_health timed out after %d seconds\n",
            $self->opts->timeout;
        kill 9, $snmpwalkpid;
      };
      alarm($self->opts->timeout);
      unlink $name.".partial";
      while (! $timedout && @trees) {
        my $tree = shift @trees;
        $SIG{CHLD} = 'IGNORE';
        my $cmd = sprintf "snmpwalk -ObentU -v%s -c %s %s %s >> %s", 
            $self->opts->protocol,
            $self->opts->community,
            $self->opts->hostname,
            $tree, $name.".partial";
        $self->trace($cmd);
        $snmpwalkpid = fork;
        if (not $snmpwalkpid) {
          exec($cmd);
        } else {
          wait();
        }
      }
      rename $name.".partial", $name if ! $timedout;
      -f $self->{pidfile} && unlink $self->{pidfile};
      if ($timedout) {
        printf "CRITICAL - timeout. There are still %d snmpwalks left\n", scalar(@trees);
        exit 3;
      } else {
        printf "OK - all requested oids are in %s\n", $name;
      }
    } else {
      printf "rm -f %s\n", $name;
      foreach ($self->trees) {
        printf "snmpwalk -ObentU -v%s -c %s %s %s >> %s\n", 
            $self->opts->protocol,
            $self->opts->community,
            $self->opts->hostname,
            $_, $name;
      }
    }
    exit 0;
  } elsif ($self->mode =~ /device::uptime/) {
    $self->{uptime} /= 60;
    my $info = sprintf 'device is up since %d minutes', $self->{uptime};
    $self->add_info($info);
    $self->set_thresholds(warning => '15:', critical => '5:');
    $self->add_message($self->check_thresholds($self->{uptime}), $info);
    $self->add_perfdata(
        label => 'uptime',
        value => $self->{uptime},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    my ($code, $message) = $self->check_messages(join => ', ', join_all => ', ');
    $NWC::Device::plugin->nagios_exit($code, $message);
  } elsif ($self->mode =~ /device::interfaces::aggregation::availability/) {
    my $aggregation = NWC::IFMIB::Component::LinkAggregation->new();
    #$self->analyze_interface_subsystem();
    $aggregation->check();
  } elsif ($self->mode =~ /device::interfaces/) {
    $self->analyze_interface_subsystem();
    $self->check_interface_subsystem();
  } elsif ($self->mode =~ /device::bgp/) {
    $self->analyze_bgp_subsystem();
    $self->check_bgp_subsystem();
  }
}

sub check_snmp_and_model {
# uptime pruefen
# dann whoami
  my $self = shift;
  if ($self->opts->snmpwalk) {
    my $response = {};
    if (! -f $self->opts->snmpwalk) {
      $self->add_message(CRITICAL, 
          sprintf 'file %s not found',
          $self->opts->snmpwalk);
    } elsif (-x $self->opts->snmpwalk) {
      my $cmd = sprintf "%s -On -v%s -c%s %s 1.3.6.1.4.1.232 2>&1",
          $self->opts->snmpwalk,
          $self->opts->protocol,
          $self->opts->community,
          $self->opts->hostname;
      open(WALK, "$cmd |");
      while (<WALK>) {
        if (/^.*?\.(232\.[\d\.]+) = .*?: (\-*\d+)/) {
          $response->{'1.3.6.1.4.1.'.$1} = $2;
        } elsif (/^.*?\.(232\.[\d\.]+) = .*?: "(.*?)"/) {
          $response->{'1.3.6.1.4.1.'.$1} = $2;
          $response->{'1.3.6.1.4.1.'.$1} =~ s/\s+$//;
        }
      }
      close WALK;
    } else {
      if (defined $self->opts->offline) {
        if ((time - (stat($self->opts->snmpwalk))[9]) > $self->opts->offline) {
          $self->add_message(UNKNOWN,
              sprintf 'snmpwalk file %s is too old', $self->opts->snmpwalk);
        }
      }
      $self->opts->override_opt('hostname', 'walkhost');
      open(MESS, $self->opts->snmpwalk);
      while(<MESS>) {
        # SNMPv2-SMI::enterprises.232.6.2.6.7.1.3.1.4 = INTEGER: 6
        if (/^([\d\.]+) = .*?INTEGER: .*\((\-*\d+)\)/) {
          # .1.3.6.1.2.1.2.2.1.8.1 = INTEGER: down(2)
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = .*?Opaque:.*?Float:.*?([\-\.\d]+)/) {
          # .1.3.6.1.4.1.2021.10.1.6.1 = Opaque: Float: 0.938965
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = STRING:\s*$/) {
          $response->{$1} = "";
        } elsif (/^([\d\.]+) = Network Address: (.*)/) {
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = Hex-STRING: (.*)/) {
          $response->{$1} = "0x".$2;
          $response->{$1} =~ s/\s+$//;
        } elsif (/^([\d\.]+) = \w+: (\-*\d+)/) {
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = \w+: "(.*?)"/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        } elsif (/^([\d\.]+) = \w+: (.*)/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        } elsif (/^([\d\.]+) = (\-*\d+)/) {
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = "(.*?)"/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        }
      }
      close MESS;
    }
    foreach my $oid (keys %$response) {
      if ($oid =~ /^\./) {
        my $nodot = $oid;
        $nodot =~ s/^\.//g;
        $response->{$nodot} = $response->{$oid};
        delete $response->{$oid};
      }
    }
    map { $response->{$_} =~ s/^\s+//; $response->{$_} =~ s/\s+$//; }
        keys %$response;
    #printf "%s\n", Data::Dumper::Dumper($response);
    $self->set_rawdata($response);
    #if (! $self->get_snmp_object('MIB-II', 'sysDescr', 0)) {
    #  $self->add_rawdata('1.3.6.1.2.1.1.1.0', 'Cisco');
    #}
    $self->whoami();
  } else {
    if (eval "require Net::SNMP") {
      my %params = ();
      my $net_snmp_version = Net::SNMP->VERSION(); # 5.002000 or 6.000000
      #$params{'-translate'} = [
      #  -all => 0x0
      #];
      #lausser#$params{'-timeout'} = $self->opts->timeout;
      $params{'-hostname'} = $self->opts->hostname;
      $params{'-version'} = $self->opts->protocol;
      if ($self->opts->port) {
        $params{'-port'} = $self->opts->port;
      }
      if ($self->opts->domain) {
        $params{'-domain'} = $self->opts->domain;
      }
      if ($self->opts->protocol eq '3') {
        $params{'-username'} = $self->opts->username;
        if ($self->opts->authpassword) {
          $params{'-authpassword'} = $self->opts->authpassword;
        }
        if ($self->opts->authprotocol) {
          $params{'-authprotocol'} = $self->opts->authprotocol;
        }
        if ($self->opts->privpassword) {
          $params{'-privpassword'} = $self->opts->privpassword;
        }
        if ($self->opts->privprotocol) {
          $params{'-privprotocol'} = $self->opts->privprotocol;
        }
      } else {
        $params{'-community'} = $self->opts->community;
      }
      my ($session, $error) = Net::SNMP->session(%params);
      if (! defined $session) {
        $self->add_message(CRITICAL, 
            sprintf 'cannot create session object: %s', $error);
        $self->debug(Data::Dumper::Dumper(\%params));
      } else {
        my $max_msg_size = $session->max_msg_size();
        $session->max_msg_size(4 * $max_msg_size);
        $NWC::Device::session = $session;
        my $sysUpTime = '1.3.6.1.2.1.1.3.0';
        my $uptime = $self->get_snmp_object('MIB-II', 'sysUpTime', 0);
        if (my $uptime = $self->get_snmp_object('MIB-II', 'sysUpTime', 0)) {
          $self->debug(sprintf 'snmp agent answered: %s', $uptime);
          $self->whoami();
        } else {
          $self->add_message(CRITICAL,
              'could not contact snmp agent');
          $session->close;
        }
      }
    } else {
      $self->add_message(CRITICAL,
          'could not find Net::SNMP module');
    }
  }
}

sub whoami {
  my $self = shift;
  my $productname = undef;
  my $sysDescr = '1.3.6.1.2.1.1.1.0';
  my $dummy = '1.3.6.1.2.1.1.5.0';
  if ($productname = $self->get_snmp_object('MIB-II', 'sysDescr', 0)) {
    $self->{productname} = $productname;
    $self->{uptime} = $self->timeticks(
        $self->get_snmp_object('MIB-II', 'sysUpTime', 0));
    $self->debug(sprintf 'uptime: %s', $self->{uptime});
    $self->debug(sprintf 'up since: %s',
        scalar localtime (time - $self->{uptime}));
    $NWC::Device::uptime = $self->{uptime};
  } else {
    $self->add_message(CRITICAL,
        'snmpwalk returns no product name (sysDescr)');
    if (! $self->opts->snmpwalk) {
      $NWC::Device::session->close;
    }
  }
  $self->debug('whoami: '.$self->{productname});
}

sub timeticks {
  my $self = shift;
  my $timestr = shift;
  if ($timestr =~ /\((\d+)\)/) {
    # Timeticks: (20718727) 2 days, 9:33:07.27
    $timestr = $1 / 100;
  } elsif ($timestr =~ /(\d+)\s*days.*?(\d+):(\d+):(\d+)\.(\d+)/) {
    # Timeticks: 2 days, 9:33:07.27
    $timestr = $1 * 24 * 3600 + $2 * 3600 + $3 * 60 + $4;
  } elsif ($timestr =~ /(\d+):(\d+):(\d+)\.(\d+)/) {
    # Timeticks: 9:33:07.27
    $timestr = $1 * 3600 + $2 * 60 + $3;
  } elsif ($timestr =~ /(\d+)\s*hour[s]*.*?(\d+):(\d+)\.(\d+)/) {
    # Timeticks: 3 hours, 42:17.98
    $timestr = $1 * 3600 + $2 * 60 + $3;
  } elsif ($timestr =~ /(\d+)\s*minute[s]*.*?(\d+)\.(\d+)/) {
    # Timeticks: 36 minutes, 01.96
    $timestr = $1 * 60 + $2;
  } elsif ($timestr =~ /(\d+)\.\d+\s*second[s]/) {
    # Timeticks: 01.02 seconds
    $timestr = $1;
  }
  return $timestr;
}

sub human_timeticks {
  my $self = shift;
  my $timeticks = shift;
  my $days = int($timeticks / 86400); 
  $timeticks -= ($days * 86400); 
  my $hours = int($timeticks / 3600); 
  $timeticks -= ($hours * 3600); 
  my $minutes = int($timeticks / 60); 
  my $seconds = $timeticks % 60; 
  $days = $days < 1 ? '' : $days .'d '; 
  return $days . sprintf "%02d:%02d:%02d", $hours, $minutes, $seconds;
}

sub get_snmp_object {
  my $self = shift;
  my $mib = shift;
  my $mo = shift;
  my $index = shift;
  if (exists $NWC::Device::mibs_and_oids->{$mib} &&
      exists $NWC::Device::mibs_and_oids->{$mib}->{$mo}) {
    my $oid = $NWC::Device::mibs_and_oids->{$mib}->{$mo}.
        (defined $index ? '.'.$index : '');
    my $response = $self->get_request(-varbindlist => [$oid]);
    if (defined $response->{$oid}) {
      if (my @symbols = $self->make_symbolic($mib, $response, [[$index]])) {
        $response->{$oid} = $symbols[0]->{$mo};
      }
    }
    return $response->{$oid};
  }
  return undef;
}

sub get_single_request_iq {
  my $self = shift;
  my %params = @_;
  my @oids = ();
  my $result = $self->get_request_iq(%params);
  foreach (keys %{$result}) {
    return $result->{$_};
  }
  return undef;
}

sub get_request_iq {
  my $self = shift;
  my %params = @_;
  my @oids = ();
  my $mib = $params{'-mib'};
  foreach my $oid (@{$params{'-molist'}}) {
    if (exists $NWC::Device::mibs_and_oids->{$mib} &&
        exists $NWC::Device::mibs_and_oids->{$mib}->{$oid}) {
      push(@oids, (exists $params{'-index'}) ?
          $NWC::Device::mibs_and_oids->{$mib}->{$oid}.'.'.$params{'-index'} :
          $NWC::Device::mibs_and_oids->{$mib}->{$oid});
    }
  }
  return $self->get_request(
      -varbindlist => \@oids);
}

sub valid_response {
  my $self = shift;
  my $mib = shift;
  my $oid = shift;
  my $index = shift;
  if (exists $NWC::Device::mibs_and_oids->{$mib} &&
      exists $NWC::Device::mibs_and_oids->{$mib}->{$oid}) {
    # make it numerical
    my $oid = $NWC::Device::mibs_and_oids->{$mib}->{$oid};
    if (defined $index) {
      $oid .= '.'.$index;
    }
    my $result = $self->get_request(
        -varbindlist => [$oid]
    );
    if (!defined($result) ||
        ! defined $result->{$oid} ||
        $result->{$oid} eq 'noSuchInstance' ||
        $result->{$oid} eq 'noSuchObject' ||
        $result->{$oid} eq 'endOfMibView') {
      return undef;
    } else {
      $self->add_rawdata($oid, $result->{$oid});
      return $result->{$oid};
    }
  } else {
    return undef;
  }
}

sub debug {
  my $self = shift;
  my $format = shift;
  $self->{trace} = -f "/tmp/check_nwc_health.trace" ? 1 : 0;
  if ($self->opts->verbose && $self->opts->verbose > 10) {
    printf("%s: ", scalar localtime);
    printf($format, @_);
    printf "\n";
  }
  if ($self->{trace}) {
    my $logfh = new IO::File;
    $logfh->autoflush(1);
    if ($logfh->open("/tmp/check_nwc_health.trace", "a")) {
      $logfh->printf("%s: ", scalar localtime);
      $logfh->printf($format, @_);
      $logfh->printf("\n");
      $logfh->close();
    }
  }
}

sub filter_name {
  my $self = shift;
  my $name = shift;
  if ($self->opts->name) {
    if ($self->opts->regexp) {
      my $pattern = $self->opts->name;
      if ($name =~ /$pattern/i) {
        return 1;
      }
    } else {
      if (lc $self->opts->name eq lc $name) {
        return 1;
      }
    }
  } else {
    return 1;
  }
  return 0;
}

sub blacklist {
  my $self = shift;
  my $type = shift;
  my $name = shift;
  $self->{blacklisted} = $self->is_blacklisted($type, $name);
}

sub add_blacklist {
  my $self = shift;
  my $list = shift;
  $NWC::Device::blacklist = join('/',
      (split('/', $self->opts->blacklist), $list));
}

sub is_blacklisted {
  my $self = shift;
  my $type = shift;
  my $name = shift;
  my $blacklisted = 0;
#  $name =~ s/\:/-/g;
  foreach my $bl_items (split(/\//, $self->opts->blacklist)) {
    if ($bl_items =~ /^(\w+):([\:\d\-,]+)$/) {
      my $bl_type = $1;
      my $bl_names = $2;
      foreach my $bl_name (split(/,/, $bl_names)) {
        if ($bl_type eq $type && $bl_name eq $name) {
          $blacklisted = 1;
        }
      }
    } elsif ($bl_items =~ /^(\w+)$/) {
      my $bl_type = $1;
      if ($bl_type eq $type) {
        $blacklisted = 1;
      }
    }
  }
  return $blacklisted;
}

sub mode {
  my $self = shift;
  return $NWC::Device::mode;
}

sub uptime {
  my $self = shift;
  return $NWC::Device::uptime;
}

sub add_message {
  my $self = shift;
  my $level = shift;
  my $message = shift;
  $NWC::Device::plugin->add_message($level, $message) 
      unless $self->{blacklisted};
  if (exists $self->{failed}) {
    if ($level == UNKNOWN && $self->{failed} == OK) {
      $self->{failed} = $level;
    } elsif ($level > $self->{failed}) {
      $self->{failed} = $level;
    }
  }
}

sub status_code {
  my $self = shift;
  return $NWC::Device::plugin->status_code(@_);
}

sub check_messages {
  my $self = shift;
  return $NWC::Device::plugin->check_messages(@_);
}

sub clear_messages {
  my $self = shift;
  return $NWC::Device::plugin->clear_messages(@_);
}

sub suppress_messages {
  my $self = shift;
  return $NWC::Device::plugin->suppress_messages(@_);
}

sub add_perfdata {
  my $self = shift;
  $NWC::Device::plugin->add_perfdata(@_);
}

sub perfdata_string {
  my $self = shift;
  $NWC::Device::plugin->perfdata_string(@_);
}

sub set_thresholds {
  my $self = shift;
  $NWC::Device::plugin->set_thresholds(@_);
}

sub force_thresholds {
  my $self = shift;
  $NWC::Device::plugin->force_thresholds(@_);
}

sub check_thresholds {
  my $self = shift;
  my @params = @_;
  ($self->{warning}, $self->{critical}) =
      $NWC::Device::plugin->get_thresholds(@params);
  return $NWC::Device::plugin->check_thresholds(@params);
}

sub get_thresholds {
  my $self = shift;
  my @params = @_;
  my @thresholds = $NWC::Device::plugin->get_thresholds(@params);
  my($warning, $critical) = $NWC::Device::plugin->get_thresholds(@params);
  $self->{warning} = $thresholds[0];
  $self->{critical} = $thresholds[1];
  return @thresholds;
}

sub has_failed {
  my $self = shift;
  return $self->{failed};
}

sub add_info {
  my $self = shift;
  my $info = shift;
  $info = $self->{blacklisted} ? $info.' (blacklisted)' : $info;
  $self->{info} = $info;
  push(@{$NWC::Device::info}, $info);
}

sub annotate_info {
  my $self = shift;
  my $annotation = shift;
  my $lastinfo = pop(@{$NWC::Device::info});
  $lastinfo .= sprintf ' (%s)', $annotation;
  push(@{$NWC::Device::info}, $lastinfo);
}

sub add_extendedinfo {
  my $self = shift;
  my $info = shift;
  $self->{extendedinfo} = $info;
  return if ! $self->opts->extendedinfo;
  push(@{$NWC::Device::extendedinfo}, $info);
}

sub get_extendedinfo {
  my $self = shift;
  return join(' ', @{$NWC::Device::extendedinfo});
}

sub add_summary {
  my $self = shift;
  my $summary = shift;
  push(@{$NWC::Device::summary}, $summary);
}

sub get_summary {
  my $self = shift;
  return join(', ', @{$NWC::Device::summary});
}

sub opts {
  my $self = shift;
  return $NWC::Device::plugin->opts();
}

sub set_rawdata {
  my $self = shift;
  $NWC::Device::rawdata = shift;
}

sub add_rawdata {
  my $self = shift;
  my $oid = shift;
  my $value = shift;
  $NWC::Device::rawdata->{$oid} = $value;
}

sub rawdata {
  my $self = shift;
  return $NWC::Device::rawdata;
}

sub add_oidtrace {
  my $self = shift;
  my $oid = shift;
  $self->debug("cache: ".$oid);
  push(@{$NWC::Device::oidtrace}, $oid);
}

sub get_snmp_table_attributes {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $indices = shift || [];
  my @entries = ();
  my $augmenting_table;
  if ($table =~ /^(.*?)\+(.*)/) {
    $table = $1;
    $augmenting_table = $2;
  }
  my $entry = $table;
  $entry =~ s/Table/Entry/g;
  if (exists $NWC::Device::mibs_and_oids->{$mib} &&
      exists $NWC::Device::mibs_and_oids->{$mib}->{$table}) {
    my $toid = $NWC::Device::mibs_and_oids->{$mib}->{$table}.'.';
    my $toidlen = length($toid);
    my @columns = grep {
      substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $toidlen) eq
          $NWC::Device::mibs_and_oids->{$mib}->{$table}.'.'
    } keys %{$NWC::Device::mibs_and_oids->{$mib}};
    if ($augmenting_table &&
        exists $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}) {
      my $toid = $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}.'.';
      my $toidlen = length($toid);
      push(@columns, grep {
        substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $toidlen) eq
            $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}.'.'
      } keys %{$NWC::Device::mibs_and_oids->{$mib}});
    }
    return @columns;
  } else {
    return ();
  }
}

sub get_request {
  my $self = shift;
  my %params = @_;
  my @notcached = ();
  foreach my $oid (@{$params{'-varbindlist'}}) {
    $self->add_oidtrace($oid);
    if (! exists NWC::Device::rawdata->{$oid}) {
      push(@notcached, $oid);
    }
  }
  if (! $self->opts->snmpwalk && (scalar(@notcached) > 0)) {
    my $result = ($NWC::Device::session->version() == 0) ?
        $NWC::Device::session->get_request(
            -varbindlist => \@notcached,
        )
        :
        $NWC::Device::session->get_request(  # get_bulk_request liefert next
            #-nonrepeaters => scalar(@notcached),
            -varbindlist => \@notcached,
        );
    foreach my $key (%{$result}) {
      $self->add_rawdata($key, $result->{$key});
    }
  }
  my $result = {};
  map { $result->{$_} = $NWC::Device::rawdata->{$_} }
      @{$params{'-varbindlist'}};
  return $result;
}

# Level1
# get_snmp_table_objects('MIB-Name', 'Table-Name', 'Table-Entry', [indices])
#
# returns array of hashrefs
# evt noch ein weiterer parameter fuer ausgewaehlte oids
#
sub get_snmp_table_objects_with_cache {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  #return $self->get_snmp_table_objects($mib, $table);
  $self->update_entry_cache(0, $mib, $table, $key_attr);
  my @indices = $self->get_cache_indices($mib, $table, $key_attr);
  my @entries = ();
  foreach ($self->get_snmp_table_objects($mib, $table, \@indices)) {
    push(@entries, $_);
  }
  return @entries;
}

sub get_snmp_table_objects {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $indices = shift || [];
  my @entries = ();
  my $augmenting_table;
  $self->debug(sprintf "get_snmp_table_objects %s %s", $mib, $table);
  if ($table =~ /^(.*?)\+(.*)/) {
    $table = $1;
    $augmenting_table = $2;
  }
  my $entry = $table;
  $entry =~ s/Table/Entry/g;
  if (scalar(@{$indices}) == 1) {
    if (exists $NWC::Device::mibs_and_oids->{$mib} &&
        exists $NWC::Device::mibs_and_oids->{$mib}->{$table}) {
      my $eoid = $NWC::Device::mibs_and_oids->{$mib}->{$entry}.'.';
      my $eoidlen = length($eoid);
      my @columns = map {
          $NWC::Device::mibs_and_oids->{$mib}->{$_}
      } grep {
        substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq
            $NWC::Device::mibs_and_oids->{$mib}->{$entry}.'.'
      } keys %{$NWC::Device::mibs_and_oids->{$mib}};
      my $index = join('.', @{$indices->[0]});
      if ($augmenting_table && 
          exists $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}) {
        my $augmenting_entry = $augmenting_table;
        $augmenting_entry =~ s/Table/Entry/g;
        my $eoid = $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_entry}.'.';
        my $eoidlen = length($eoid);
        push(@columns, map {
            $NWC::Device::mibs_and_oids->{$mib}->{$_}
        } grep {
          substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq
              $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}.'.'
        } keys %{$NWC::Device::mibs_and_oids->{$mib}});
      }
      my  $result = $self->get_entries(
          -startindex => $index,
          -endindex => $index,
          -columns => \@columns,
      );
      @entries = $self->make_symbolic($mib, $result, $indices);
      @entries = map { $_->{indices} = shift @{$indices}; $_ } @entries;
    }
  } elsif (scalar(@{$indices}) > 1) {
    # man koennte hier pruefen, ob die indices aufeinanderfolgen
    # und dann get_entries statt get_table aufrufen
    if (exists $NWC::Device::mibs_and_oids->{$mib} &&
        exists $NWC::Device::mibs_and_oids->{$mib}->{$table}) {
      my $result = {};
      my $eoid = $NWC::Device::mibs_and_oids->{$mib}->{$entry}.'.';
      my $eoidlen = length($eoid);
      my @columns = map {
          $NWC::Device::mibs_and_oids->{$mib}->{$_}
      } grep {
        substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq
            $NWC::Device::mibs_and_oids->{$mib}->{$entry}.'.'
      } keys %{$NWC::Device::mibs_and_oids->{$mib}};
      my @sortedindices = map { $_->[0] }
          sort { $a->[1] cmp $b->[1] }
              map { [$_,
                  join '', map { sprintf("%30d",$_) } split( /\./, $_)
              ] } map { join('.', @{$_})} @{$indices};
      my $startindex = $sortedindices[0];
      my $endindex = $sortedindices[$#sortedindices];
      if (0) {
        # holzweg. dicke ciscos liefern unvollstaendiges resultat, d.h.
        # bei 138,19,157 kommt nur 138..144, dann ist schluss.
        # maxrepetitions bringt nichts.
        $result = $self->get_entries(
            -startindex => $startindex,
            -endindex => $endindex,
            -columns => \@columns,
        );
        if (! $result) {
          $result = $self->get_entries(
              -startindex => $startindex,
              -endindex => $endindex,
              -columns => \@columns,
              -maxrepetitions => 0,
          );
        }
      } else {
        foreach my $ifidx (@sortedindices) {
          my $ifresult = $self->get_entries(
              -startindex => $ifidx,
              -endindex => $ifidx,
              -columns => \@columns,
          );
          map { $result->{$_} = $ifresult->{$_} }
              keys %{$ifresult};
        }
      }
      if ($augmenting_table &&
          exists $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}) {
        my $entry = $augmenting_table;
        $entry =~ s/Table/Entry/g;
        my $eoid = $NWC::Device::mibs_and_oids->{$mib}->{$entry}.'.';
        my $eoidlen = length($eoid);
        my @columns = map {
            $NWC::Device::mibs_and_oids->{$mib}->{$_}
        } grep {
          substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $eoidlen) eq
              $NWC::Device::mibs_and_oids->{$mib}->{$entry}.'.'
        } keys %{$NWC::Device::mibs_and_oids->{$mib}};
        foreach my $ifidx (@sortedindices) {
          my $ifresult = $self->get_entries(
              -startindex => $ifidx,
              -endindex => $ifidx,
              -columns => \@columns,
          );
          map { $result->{$_} = $ifresult->{$_} }
              keys %{$ifresult};
        }
      }
      # now we have numerical_oid+index => value
      # needs to become symboic_oid => value
      #my @indices =
      # $self->get_indices($NWC::Device::mibs_and_oids->{$mib}->{$entry});
      @entries = $self->make_symbolic($mib, $result, $indices);
      @entries = map { $_->{indices} = shift @{$indices}; $_ } @entries;
    }
  } else {
    if (exists $NWC::Device::mibs_and_oids->{$mib} &&
        exists $NWC::Device::mibs_and_oids->{$mib}->{$table}) {
      $self->debug(sprintf "get_snmp_table_objects calls get_table %s",
          $NWC::Device::mibs_and_oids->{$mib}->{$table});
      my $result = $self->get_table(
          -baseoid => $NWC::Device::mibs_and_oids->{$mib}->{$table});
      $self->debug(sprintf "get_snmp_table_objects get_table returns %d oids",
          scalar(keys %{$result}));
      # now we have numerical_oid+index => value
      # needs to become symboic_oid => value
      my @indices = 
          $self->get_indices(
              -baseoid => $NWC::Device::mibs_and_oids->{$mib}->{$entry},
              -oids => [keys %{$result}]);
      $self->debug(sprintf "get_snmp_table_objects get_table returns %d indices",
          scalar(@indices));
      @entries = $self->make_symbolic($mib, $result, \@indices);
      @entries = map { $_->{indices} = shift @indices; $_ } @entries;
    }
  }
  @entries = map { $_->{flat_indices} = join(".", @{$_->{indices}}); $_ } @entries;
  return @entries;
}

# make_symbolic
# mib is the name of a mib (must be in mibs_and_oids)
# result is a hash-key oid->value
# indices is a array ref of array refs. [[1],[2],...] or [[1,0],[1,1],[2,0]..
sub make_symbolic {
  my $self = shift;
  my $mib = shift;
  my $result = shift;
  my $indices = shift;
  my @entries = ();
  foreach my $index (@{$indices}) {
    # skip [], [[]], [[undef]]
    if (ref($index) eq "ARRAY") {
      if (scalar(@{$index}) == 0) {
        next;
      } elsif (!defined $index->[0]) {
        next;
      }
    }
    my $mo = {};
    my $idx = join('.', @{$index}); # index can be multi-level
    foreach my $symoid
        (keys %{$NWC::Device::mibs_and_oids->{$mib}}) {
      my $oid = $NWC::Device::mibs_and_oids->{$mib}->{$symoid};
      if (ref($oid) ne 'HASH') {
        my $fulloid = $oid . '.'.$idx;
        if (exists $result->{$fulloid}) {
          if (exists $NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}) {
            if (ref($NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}) eq 'HASH') {
              if (exists $NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$fulloid}}) {
                $mo->{$symoid} = $NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$fulloid}};
              } else {
                $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              }
            } elsif ($NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'} =~ /^OID::(.*)/) {
              my $othermib = $1;
              my @result = grep { $NWC::Device::mibs_and_oids->{$othermib}->{$_} eq $result->{$fulloid} } keys %{$NWC::Device::mibs_and_oids->{$othermib}};
              if (scalar(@result)) {
                $mo->{$symoid} = $result[0];
              } else {
                $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              }
            } elsif ($NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'} =~ /^(.*?)::(.*)/) {
              my $mib = $1;
              my $definition = $2;
              if  (exists $NWC::Device::definitions->{$mib} && exists $NWC::Device::definitions->{$mib}->{$definition}
                  && exists $NWC::Device::definitions->{$mib}->{$definition}->{$result->{$fulloid}}) {
                $mo->{$symoid} = $NWC::Device::definitions->{$mib}->{$definition}->{$result->{$fulloid}};
              } else {
                $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              }
            } else {
              $mo->{$symoid} = 'unknown_'.$result->{$fulloid};
              # oder $NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}?
            }
          } else {
            $mo->{$symoid} = $result->{$fulloid};
          }
        }
      }
    }
    push(@entries, $mo);
  }
  if (@{$indices} and scalar(@{$indices}) == 1 and !defined $indices->[0]->[0]) {
    my $mo = {};
    foreach my $symoid
        (keys %{$NWC::Device::mibs_and_oids->{$mib}}) {
      my $oid = $NWC::Device::mibs_and_oids->{$mib}->{$symoid};
      if (ref($oid) ne 'HASH') {
        if (exists $result->{$oid}) {
          if (exists $NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}) {
            if (ref($NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}) eq 'HASH') {
              if (exists $NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$oid}}) {
                $mo->{$symoid} = $NWC::Device::mibs_and_oids->{$mib}->{$symoid.'Definition'}->{$result->{$oid}};
                push(@entries, $mo);
              }
            }
          }
        }
      }
    }
  }
  return @entries;
}

# Level2
# - get_table from Net::SNMP
# - get all baseoid-matching oids from rawdata
sub get_table {
  my $self = shift;
  my %params = @_;
  $self->add_oidtrace($params{'-baseoid'});
  if (! $self->opts->snmpwalk) {
    my @notcached = ();
    $self->debug(sprintf "get_table %s", Data::Dumper::Dumper(\%params));
    my $result = $NWC::Device::session->get_table(%params);
    $self->debug(sprintf "get_table returned %d oids", scalar(keys %{$result}));
    if (scalar(keys %{$result}) == 0) {
      $self->debug(sprintf "get_table error: %s", 
          $NWC::Device::session->error());
      $self->debug("get_table error: try fallback");
      $params{'-maxrepetitions'} = 1;
      $self->debug(sprintf "get_table %s", Data::Dumper::Dumper(\%params));
      $result = $NWC::Device::session->get_table(%params);
      $self->debug(sprintf "get_table returned %d oids", scalar(keys %{$result}));
      if (scalar(keys %{$result}) == 0) {
        $self->debug(sprintf "get_table error: %s", 
            $NWC::Device::session->error());
        $self->debug("get_table error: no more fallbacks. Try --protocol 1");
      }
    }
    foreach my $key (keys %{$result}) {
      $self->add_rawdata($key, $result->{$key});
    }
  }
  return $self->get_matching_oids(
      -columns => [$params{'-baseoid'}]);
}

sub get_entries {
  my $self = shift;
  my %params = @_;
  # [-startindex]
  # [-endindex]
  # -columns
  my $result = {};
  $self->debug(sprintf "get_entries %s", Data::Dumper::Dumper(\%params));
  if (! $self->opts->snmpwalk) {
    my %newparams = ();
    $newparams{'-startindex'} = $params{'-startindex'}
        if defined $params{'-startindex'};
    $newparams{'-endindex'} = $params{'-endindex'}     
        if defined $params{'-endindex'};
    $newparams{'-columns'} = $params{'-columns'};
    $result = $NWC::Device::session->get_entries(%newparams);
    if (! $result) {
      $newparams{'-maxrepetitions'} = 0;
      $result = $NWC::Device::session->get_entries(%newparams);
      if (! $result) {
        $self->debug(sprintf "get_entries tries last fallback");
        delete $newparams{'-endindex'};
        delete $newparams{'-startindex'};
        delete $newparams{'-maxrepetitions'};
        $result = $NWC::Device::session->get_entries(%newparams);
      }
    }
    foreach my $key (keys %{$result}) {
      $self->add_rawdata($key, $result->{$key});
    }
  } else {
    my $preresult = $self->get_matching_oids(
        -columns => $params{'-columns'});
    foreach (keys %{$preresult}) {
      $result->{$_} = $preresult->{$_};
    }
    my @sortedkeys = map { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
            map { [$_,
                    join '', map { sprintf("%30d",$_) } split( /\./, $_)
                  ] } keys %{$result};
    my @to_del = ();
    if ($params{'-startindex'}) {
      foreach my $resoid (@sortedkeys) {
        foreach my $oid (@{$params{'-columns'}}) {
          my $poid = $oid.'.';
          my $lpoid = length($poid);
          if (substr($resoid, 0, $lpoid) eq $poid) {
            my $oidpattern = $poid;
            $oidpattern =~ s/\./\\./g;
            if ($resoid =~ /^$oidpattern(.+)$/) {
              if ($1 lt $params{'-startindex'}) {
                push(@to_del, $oid.'.'.$1);
              }
            }
          }
        }
      }
    }
    if ($params{'-endindex'}) {
      foreach my $resoid (@sortedkeys) {
        foreach my $oid (@{$params{'-columns'}}) {
          my $poid = $oid.'.';
          my $lpoid = length($poid);
          if (substr($resoid, 0, $lpoid) eq $poid) {
            my $oidpattern = $poid;
            $oidpattern =~ s/\./\\./g;
            if ($resoid =~ /^$oidpattern(.+)$/) {
              if ($1 gt $params{'-endindex'}) {
                push(@to_del, $oid.'.'.$1);
              }
            }
          }
        }
      } 
    }
    foreach (@to_del) {
      delete $result->{$_};
    }
  }
  return $result;
}

# Level2
# helper function
sub get_matching_oids {
  my $self = shift;
  my %params = @_;
  my $result = {};
  $self->debug(sprintf "get_matching_oids %s", Data::Dumper::Dumper(\%params));
  foreach my $oid (@{$params{'-columns'}}) {
    my $oidpattern = $oid;
    $oidpattern =~ s/\./\\./g;
    map { $result->{$_} = $NWC::Device::rawdata->{$_} }
        grep /^$oidpattern(?=\.|$)/, keys %{$NWC::Device::rawdata};
  }
  $self->debug(sprintf "get_matching_oids returns %d from %d oids", 
      scalar(keys %{$result}), scalar(keys %{$NWC::Device::rawdata}));
  return $result;
}

sub valdiff {
  my $self = shift;
  my $pparams = shift;
  my %params = %{$pparams};
  my @keys = @_;
  my $now = time;
  my $newest_history_set = {};
  my $last_values = $self->load_state(%params) || eval {
    my $empty_events = {};
    foreach (@keys) {
      if (ref($self->{$_}) eq "ARRAY") {
        $empty_events->{$_} = [];
      } else {
        $empty_events->{$_} = 0;
      }
    }
    $empty_events->{timestamp} = 0;
    if ($self->opts->lookback) {
      $empty_events->{lookback_history} = {};
    }
    $empty_events;
  };
  foreach (@keys) {
    if ($self->opts->lookback) {
      # find a last_value in the history which fits lookback best
      # and overwrite $last_values->{$_} with historic data
      if (exists $last_values->{lookback_history}->{$_}) {
        foreach my $date (sort {$a <=> $b} keys %{$last_values->{lookback_history}->{$_}}) {
            $newest_history_set->{$_} = $last_values->{lookback_history}->{$_}->{$date};
            $newest_history_set->{timestamp} = $date;
        }
        foreach my $date (sort {$a <=> $b} keys %{$last_values->{lookback_history}->{$_}}) {
          if ($date >= ($now - $self->opts->lookback)) {
            $last_values->{$_} = $last_values->{lookback_history}->{$_}->{$date};
            $last_values->{timestamp} = $date;
            last;
          } else {
            delete $last_values->{lookback_history}->{$_}->{$date};
          }
        }
      }
    }
    if ($self->{$_} =~ /^\d+$/) {
      $last_values->{$_} = 0 if ! exists $last_values->{$_};
      if ($self->{$_} >= $last_values->{$_}) {
        $self->{'delta_'.$_} = $self->{$_} - $last_values->{$_};
      } else {
        # vermutlich db restart und zaehler alle auf null
        $self->{'delta_'.$_} = $self->{$_};
      }
      $self->debug(sprintf "delta_%s %f", $_, $self->{'delta_'.$_});
    } elsif (ref($self->{$_}) eq "ARRAY") {
      if ((! exists $last_values->{$_} || ! defined $last_values->{$_}) && exists $params{lastarray}) {
        # innerhalb der lookback-zeit wurde nichts in der lookback_history
        # gefunden. allenfalls irgendwas aelteres. normalerweise
        # wuerde jetzt das array als [] initialisiert.
        # d.h. es wuerde ein delta geben, @found s.u.
        # wenn man das nicht will, sondern einfach aktuelles array mit
        # dem array des letzten laufs vergleichen will, setzt man lastarray
        $last_values->{$_} = %{$newest_history_set} ?
            $newest_history_set->{$_} : []
      } elsif ((! exists $last_values->{$_} || ! defined $last_values->{$_}) && ! exists $params{lastarray}) {
        $last_values->{$_} = [] if ! exists $last_values->{$_};
      } elsif (exists $last_values->{$_} && ! defined $last_values->{$_}) {
        # $_ kann es auch ausserhalb des lookback_history-keys als normalen
        # key geben. der zeigt normalerweise auf den entspr. letzten 
        # lookback_history eintrag. wurde der wegen ueberalterung abgeschnitten
        # ist der hier auch undef.
        $last_values->{$_} = %{$newest_history_set} ?
            $newest_history_set->{$_} : []
      }
      my %saved = map { $_ => 1 } @{$last_values->{$_}};
      my %current = map { $_ => 1 } @{$self->{$_}};
      my @found = grep(!defined $saved{$_}, @{$self->{$_}});
      my @lost = grep(!defined $current{$_}, @{$last_values->{$_}});
      $self->{'delta_found_'.$_} = \@found;
      $self->{'delta_lost_'.$_} = \@lost;
    }
  }
  $self->{'delta_timestamp'} = $now - $last_values->{timestamp};
  $params{save} = eval {
    my $empty_events = {};
    foreach (@keys) {
      $empty_events->{$_} = $self->{$_};
    }
    $empty_events->{timestamp} = $now;
    if ($self->opts->lookback) {
      $empty_events->{lookback_history} = $last_values->{lookback_history};
      foreach (@keys) {
        $empty_events->{lookback_history}->{$_}->{$now} = $self->{$_};
      }
    }
    $empty_events;
  };
  $self->save_state(%params);
}

sub create_statefilesdir {
  my $self = shift;
  if (! -d $NWC::Device::statefilesdir) {
    eval {
      use File::Path;
      mkpath $NWC::Device::statefilesdir;
    };
    if ($@ || ! -w $NWC::Device::statefilesdir) {
      $self->add_message(UNKNOWN,
        sprintf "cannot create status dir %s! check your filesystem (permissions/usage/integrity) and disk devices", $NWC::Device::statefilesdir);
    }
  } elsif (! -w $NWC::Device::statefilesdir) {
    $self->add_message(UNKNOWN,
        sprintf "cannot write status dir %s! check your filesystem (permissions/usage/integrity) and disk devices", $NWC::Device::statefilesdir);
  }
}

sub create_statefile {
  my $self = shift;
  my %params = @_;
  my $extension = "";
  $extension .= $params{name} ? '_'.$params{name} : '';
  if ($self->opts->community) { 
    $extension .= md5_hex($self->opts->community);
  }
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  if ($self->opts->snmpwalk && ! $self->opts->hostname) {
    return sprintf "%s/%s_%s%s", $NWC::Device::statefilesdir,
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk),
        $self->opts->mode, lc $extension;
  } elsif ($self->opts->snmpwalk && $self->opts->hostname eq "walkhost") {
    return sprintf "%s/%s_%s%s", $NWC::Device::statefilesdir,
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk),
        $self->opts->mode, lc $extension;
  } else {
    return sprintf "%s/%s_%s%s", $NWC::Device::statefilesdir,
        $self->opts->hostname, $self->opts->mode, lc $extension;
  }
}

sub schimpf {
  my $self = shift;
  printf "statefilesdir %s is not writable.\nYou didn't run this plugin as root, didn't you?\n", $NWC::Device::statefilesdir;
}

sub protect_value {
  my $self = shift;
  my $ident = shift;
  my $key = shift;
  my $validfunc = shift;
  if (ref($validfunc) ne "CODE" && $validfunc eq "percent") {
printf "validfunc is a %s\n", $validfunc;
    $validfunc = sub {
      my $value = shift;
      return ($value < 0 || $value > 100) ? 0 : 1;
    };
printf "validfunc is now a %s\n", ref($validfunc);
  }
  if (&$validfunc($self->{$key})) {
    $self->save_state(name => 'protect_'.$ident.'_'.$key, save => {
        $key => $self->{$key},
        exception => 0,
    });
  } else {
    # if the device gives us an clearly wrong value, simply use the last value.
    my $laststate = $self->load_state(name => 'protect_'.$ident.'_'.$key);
    $self->debug(sprintf "self->{%s} is %s and invalid for the %dth time",
        $key, $self->{$key}, $laststate->{exception} + 1);
    if ($laststate->{exception} <= 5) {
      # but only 5 times. 
      # if the error persists, somebody has to check the device.
      $self->{$key} = $laststate->{$key};
    }
    $self->save_state(name => 'protect_'.$ident.'_'.$key, save => {
        $key => $laststate->{$key},
        exception => $laststate->{exception}++,
    });
  }
}

sub save_state {
  my $self = shift;
  my %params = @_;
  $self->create_statefilesdir();
  my $statefile = $self->create_statefile(%params);
  if ((ref($params{save}) eq "HASH") && exists $params{save}->{timestamp}) {
    $params{save}->{localtime} = scalar localtime $params{save}->{timestamp};
  } 
  my $seekfh = new IO::File;
  if ($seekfh->open($statefile, "w")) {
    $seekfh->printf("%s", Data::Dumper::Dumper($params{save}));
    $seekfh->close();
    $self->debug(sprintf "saved %s to %s",
        Data::Dumper::Dumper($params{save}), $statefile);
  } else {
    $self->add_message(UNKNOWN,
        sprintf "cannot write status file %s! check your filesystem (permissions/usage/integrity) and disk devices", $statefile);
  }
}

sub load_state {
  my $self = shift;
  my %params = @_;
  my $statefile = $self->create_statefile(%params);
  if ( -f $statefile) {
    our $VAR1;
    eval {
      require $statefile;
    };
    if($@) {
      printf "rumms\n";
    }
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    return $VAR1;
  } else { 
    return undef;
  }
}

sub create_interface_cache_file {
  my $self = shift;
  my $extension = "";
  if ($self->opts->snmpwalk && ! $self->opts->hostname) {
    $self->opts->override_opt('hostname',
        'snmpwalk.file'.md5_hex($self->opts->snmpwalk))
  }
  if ($self->opts->community) { 
    $extension .= md5_hex($self->opts->community);
  }
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  return sprintf "%s/%s_interface_cache_%s", $NWC::Device::statefilesdir,
      $self->opts->hostname, lc $extension;
}

sub dumper {
  my $self = shift;
  my $object = shift;
  my $run = $object->{runtime};
  delete $object->{runtime};
  printf STDERR "%s\n", Data::Dumper::Dumper($object);
  $object->{runtime} = $run;
}

sub no_such_mode {
  my $self = shift;
  my %params = @_;
  printf "Mode %s is not implemented for this type of device\n",
      $self->opts->mode;
  exit 0;
}

# get_cached_table_entries
#   get_table nur die table-basoid
#   mit liste von indices
#     get_entries -startindex x -endindex x konsekutive indices oder einzeln

sub get_table_entries {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $elements = shift;
  my $oids = {};
  my $entry;
  if (exists $NWC::Device::mibs_and_oids->{$mib} &&
      exists $NWC::Device::mibs_and_oids->{$mib}->{$table}) {
    foreach my $key (keys %{$NWC::Device::mibs_and_oids->{$mib}}) {
      if ($NWC::Device::mibs_and_oids->{$mib}->{$key} =~
          /^$NWC::Device::mibs_and_oids->{$mib}->{$table}/) {
        $oids->{$key} = $NWC::Device::mibs_and_oids->{$mib}->{$key};
      }
    }
  }
  ($entry = $table) =~ s/Table/Entry/g;
  return $self->get_entries($oids, $entry);
}


sub xget_entries {
  my $self = shift;
  my $oids = shift;
  my $entry = shift;
  my $fallback = shift;
  my @params = ();
  my @indices = $self->get_indices($oids->{$entry});
  foreach (@indices) {
    my @idx = @{$_};
    my %params = ();
    my $maxdimension = scalar(@idx) - 1;
    foreach my $idxnr (1..scalar(@idx)) {
      $params{'index'.$idxnr} = $_->[$idxnr - 1];
    }
    foreach my $oid (keys %{$oids}) {
      next if $oid =~ /Table$/;
      next if $oid =~ /Entry$/;
      # there may be scalar oids ciscoEnvMonTemperatureStatusValue = curr. temp.
      next if ($oid =~ /Value$/ && ref ($oids->{$oid}) eq 'HASH');
      if (exists $oids->{$oid.'Value'}) {
        $params{$oid} = $self->get_object_value(
            $oids->{$oid}, $oids->{$oid.'Value'}, @idx);
      } else {
        $params{$oid} = $self->get_object($oids->{$oid}, @idx);
      }
    }     
    push(@params, \%params);
  }
  if (! $fallback && scalar(@params) == 0) {
    if ($NWC::Device::session) {
      my $table = $entry;
      $table =~ s/(.*)\.\d+$/$1/;
      my $result = $self->get_table(
          -baseoid => $oids->{$table}
      );
      if ($result) {
        foreach my $key (keys %{$result}) {
          $self->add_rawdata($key, $result->{$key});
        }
        @params = $self->get_entries($oids, $entry, 1);
      }
      #printf "%s\n", Data::Dumper::Dumper($result);
    }
  }
  return @params;
}

sub get_indices {
  my $self = shift;
  my %params = @_;
  # -baseoid : entry
  # find all oids beginning with $entry
  # then skip one field for the sequence
  # then read the next numindices fields
  my $entrypat = $params{'-baseoid'};
  $entrypat =~ s/\./\\\./g;
  my @indices = map {
      /^$entrypat\.\d+\.(.*)/ && $1;
  } grep {
      /^$entrypat/
  } keys %{$NWC::Device::rawdata};
  my %seen = ();
  my @o = map {[split /\./]} sort grep !$seen{$_}++, @indices;
  return @o;
}

sub get_size {
  my $self = shift;
  my $entry = shift;
  my $entrypat = $entry;
  $entrypat =~ s/\./\\\./g;
  my @entries = grep {
      /^$entrypat/
  } keys %{$NWC::Device::rawdata};
  return scalar(@entries);
}

sub get_object {
  my $self = shift;
  my $object = shift;
  my @indices = @_;
  #my $oid = $object.'.'.join('.', @indices);
  my $oid = $object;
  $oid .= '.'.join('.', @indices) if (@indices);
  return $NWC::Device::rawdata->{$oid};
}

sub get_object_value {
  my $self = shift;
  my $object = shift;
  my $values = shift;
  my @indices = @_;
  my $key = $self->get_object($object, @indices);
  if (defined $key) {
    return $values->{$key};
  } else {
    return undef;
  }
}

#SNMP::Utils::counter([$idxs1, $idxs2], $idx1, $idx2),
# this flattens a n-dimensional array and returns the absolute position
# of the element at position idx1,idx2,...,idxn
# element 1,2 in table 0,0 0,1 0,2 1,0 1,1 1,2 2,0 2,1 2,2 is at pos 6
sub get_number {
  my $self = shift;
  my $indexlists = shift; #, zeiger auf array aus [1, 2]
  my @element = @_;
  my $dimensions = scalar(@{$indexlists->[0]});
  my @sorted = ();
  my $number = 0;
  if ($dimensions == 1) {
    @sorted =
        sort { $a->[0] <=> $b->[0] } @{$indexlists};
  } elsif ($dimensions == 2) {
    @sorted =
        sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{$indexlists};
  } elsif ($dimensions == 3) {
    @sorted =
        sort { $a->[0] <=> $b->[0] ||
               $a->[1] <=> $b->[1] ||
               $a->[2] <=> $b->[2] } @{$indexlists};
  }
  foreach (@sorted) {
    if ($dimensions == 1) {
      if ($_->[0] == $element[0]) {
        last;
      }
    } elsif ($dimensions == 2) {
      if ($_->[0] == $element[0] && $_->[1] == $element[1]) {
        last;
      }
    } elsif ($dimensions == 3) {
      if ($_->[0] == $element[0] &&
          $_->[1] == $element[1] &&
          $_->[2] == $element[2]) {
        last;
      }
    }
    $number++;
  }
  return ++$number;
}

sub mib {
  my $self = shift;
  my $mib = shift;
  my $condition = {
      0 => 'other',
      1 => 'ok',
      2 => 'degraded',
      3 => 'failed',
  };
  my $MibRevMajor = $mib.'.1.0';
  my $MibRevMinor = $mib.'.2.0';
  my $MibRevCondition = $mib.'.3.0';
  return (
      $self->SNMP::Utils::get_object($MibRevMajor),
      $self->SNMP::Utils::get_object($MibRevMinor),
      $self->SNMP::Utils::get_object_value($MibRevCondition, $condition));
};

sub update_entry_cache {
  my $self = shift;
  my $force = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  my $statefile = lc sprintf "%s/%s_%s_%s-%s_%s_cache",
      $NWC::Device::statefilesdir, $self->opts->hostname,
      $self->opts->mode, $mib, $table, join('#', @{$key_attr});
  my $update = time - 3600;
  #my $update = time - 1;
  if ($force || ! -f $statefile || ((stat $statefile)[9]) < ($update)) {
    $self->debug(sprintf 'force update of %s %s %s %s cache',
        $self->opts->hostname, $self->opts->mode, $mib, $table);
    $self->{$cache} = {};
    foreach my $entry ($self->get_snmp_table_objects($mib, $table)) {
      my $key = join('#', map { $entry->{$_} } @{$key_attr});
      my $hash = $key . '-//-' . join('.', @{$entry->{indices}});
      $self->{$cache}->{$hash} = $entry->{indices};
    }
    $self->save_cache($mib, $table, $key_attr);
  }
  $self->load_cache($mib, $table, $key_attr);
}

#  $self->update_entry_cache(0, $mib, $table, $key_attr);
#  my @indices = $self->get_cache_indices();
sub get_cache_indices {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  my @indices = ();
  foreach my $key (keys %{$self->{$cache}}) {
    my ($descr, $index) = split('-//-', $key, 2);
    if ($self->opts->name) {
      if ($self->opts->regexp) {
        my $pattern = $self->opts->name;
        if ($descr =~ /$pattern/i) {
          push(@indices, $self->{$cache}->{$key});
        }
      } else {
        if ($self->opts->name =~ /^\d+$/) {
          if ($index == 1 * $self->opts->name) {
            push(@indices, [1 * $self->opts->name]);
          }
        } else {
          if (lc $descr eq lc $self->opts->name) {
            push(@indices, $self->{$cache}->{$key});
          }
        }
      }
    } else {
      push(@indices, $self->{$cache}->{$key});
    }
  }
  return @indices;
  return map { join('.', ref($_) eq "ARRAY" ? @{$_} : $_) } @indices;
}

sub save_cache {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  $self->create_statefilesdir();
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  my $statefile = lc sprintf "%s/%s_%s_%s-%s_%s_cache",
      $NWC::Device::statefilesdir, $self->opts->hostname,
      $self->opts->mode, $mib, $table, join('#', @{$key_attr});
  open(STATE, ">".$statefile.".".$$);
  printf STATE Data::Dumper::Dumper($self->{$cache});
  close STATE;
  rename $statefile.".".$$, $statefile;
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($self->{$cache}), $statefile);
}

sub load_cache {
  my $self = shift;
  my $mib = shift;
  my $table = shift;
  my $key_attr = shift;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache", 
      $mib, $table, join('#', @{$key_attr});
  my $statefile = lc sprintf "%s/%s_%s_%s-%s_%s_cache",
      $NWC::Device::statefilesdir, $self->opts->hostname,
      $self->opts->mode, $mib, $table, join('#', @{$key_attr});
  $self->{$cache} = {};
  if ( -f $statefile) {
    our $VAR1;
    our $VAR2;
    eval {
      require $statefile;
    };
    if($@) {
      printf "rumms\n";
    }
    # keinesfalls mehr require verwenden!!!!!!
    # beim require enthaelt VAR1 andere werte als beim slurp
    # und zwar diejenigen, die beim letzten save_cache geschrieben wurden.
    my $content = do { local (@ARGV, $/) = $statefile; my $x = <>; close ARGV; $x };
    $VAR1 = eval "$content";
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    $self->{$cache} = $VAR1;
  }
}

sub check_pidfile {
  my $self = shift;
  my $fh = new IO::File;
  if ($fh->open($self->{pidfile}, "r")) {
    my $pid = $fh->getline();
    $fh->close();
    if (! $pid) {
      $self->debug("Found pidfile %s with no valid pid. Exiting.",
          $self->{pidfile});
      return 0;
    } else {
      $self->debug("Found pidfile %s with pid %d", $self->{pidfile}, $pid);
      kill 0, $pid;
      if ($! == Errno::ESRCH) {
        $self->debug("This pidfile is stale. Writing a new one");
        $self->write_pidfile();
        return 1;
      } else {
        $self->debug("This pidfile is held by a running process. Exiting");
        return 0;
      }
    }
  } else {
    $self->debug("Found no pidfile. Writing a new one");
    $self->write_pidfile();
    return 1;
  }
}

sub write_pidfile {
  my $self = shift;
  if (! -d dirname($self->{pidfile})) {
    eval "require File::Path;";
    if (defined(&File::Path::mkpath)) {
      import File::Path;
      eval { mkpath(dirname($self->{pidfile})); };
    } else {
      my @dirs = ();
      map {
          push @dirs, $_;
          mkdir(join('/', @dirs))
              if join('/', @dirs) && ! -d join('/', @dirs);
      } split(/\//, dirname($self->{pidfile}));
    }
  }
  my $fh = new IO::File;
  $fh->autoflush(1);
  if ($fh->open($self->{pidfile}, "w")) {
    $fh->printf("%s", $$);
    $fh->close();
  } else {
    $self->debug("Could not write pidfile %s", $self->{pidfile});
    die "pid file could not be written";
  }
}

sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      NWC::IFMIB::Component::InterfaceSubsystem->new();
}

sub analyze_bgp_subsystem {
  my $self = shift;
  $self->{components}->{bgp_subsystem} =
      NWC::BGP::Component::PeerSubsystem->new();
}

sub shinken_interface_subsystem {
  my $self = shift;
  my $attr = sprintf "%s", join(',', map {
      sprintf '%s$(%s)$$()$', $_->{ifDescr}, $_->{ifIndex}
  } @{$self->{components}->{interface_subsystem}->{interfaces}});
  printf <<'EOEO', $self->opts->hostname(), $self->opts->hostname(), $attr;
define host {
  host_name                     %s
  address                       %s
  use                           default-host
  _interfaces                   %s

}
EOEO
  printf <<'EOEO', $self->opts->hostname();
define service {
  host_name                     %s
  service_description           net_cpu
  check_command                 check_nwc_health!cpu-load!80%%!90%%
}
EOEO
  printf <<'EOEO', $self->opts->hostname();
define service {
  host_name                     %s
  service_description           net_mem
  check_command                 check_nwc_health!memory-usage!80%%!90%%
}
EOEO
  printf <<'EOEO', $self->opts->hostname();
define service {
  host_name                     %s
  service_description           net_ifusage_$KEY$
  check_command                 check_nwc_health!interface-usage!$VALUE1$!$VALUE2$
  duplicate_foreach             _interfaces
  default_value                 80%%|90%%
}
EOEO
}



sub AUTOLOAD {
  my $self = shift;
  return if ($AUTOLOAD =~ /DESTROY/);    
  if ($AUTOLOAD =~ /^(.*)::check_(.*)_subsystem$/) {
    my $class = $1;
    my $subsystem = sprintf "%s_subsystem", $2;
    $self->{components}->{$subsystem}->check();
    $self->{components}->{$subsystem}->dump()
        if $self->opts->verbose >= 2;
  }
}

