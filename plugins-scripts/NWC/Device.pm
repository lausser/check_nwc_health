package NWC::Device;

use strict;
use IO::File;
use File::Basename;
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
      } elsif ($self->{productname} =~ /NetScreen/i) {
        bless $self, 'NWC::NetScreen';
        $self->debug('using NWC::NetScreen');
      } elsif ($self->{productname} =~ /Nortel/i) {
        bless $self, 'NWC::Nortel';
        $self->debug('using NWC::Nortel');
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
      } elsif ($self->{productname} =~ /Fibre Channel Switch/i) {
        bless $self, 'NWC::Brocade';
        $self->debug('using NWC::Brocade');
      } elsif ($self->{productname} =~ /^(GS|FS)/i) {
        bless $self, 'NWC::Netscreen';
        $self->debug('using NWC::Netscreen');
      } elsif ($self->{productname} =~ /SecureOS/i) {
        bless $self, 'NWC::SecureOS';
        $self->debug('using NWC::SecureOS');
      } elsif ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i) {
        bless $self, 'NWC::F5';
        $self->debug('using NWC::F5');
      } elsif ($self->{productname} =~ /linuxlocal/i) {
        bless $self, 'Server::Linux';
        $self->debug('using Server::Linux');
      } else {
        $self->add_message(CRITICAL,
            sprintf('unknown device%s', $self->{productname} eq 'unknown' ?
                '' : '('.$self->{productname}.')'));
      }
      if ($self->mode =~ /device::walk/) {
        if ($self->can("trees")) {
          my @trees = $self->trees;
          my $name = $0;
          $name =~ s/.*\///g;
          $name = sprintf "/tmp/snmpwalk_%s_%s", $name, $self->opts->hostname;
          printf "rm -f %s\n", $name;
          foreach ($self->trees) {
            printf "snmpwalk -On -v%s -c %s %s %s >> %s\n", 
                $self->opts->protocol,
                $self->opts->community,
                $self->opts->hostname,
                $_, $name;
          }
        }
        exit 0;
      } elsif ($self->mode =~ /device::uptime/) {
        $self->{uptime} = $self->get_snmp_object('MIB-II', 'sysUpTime', 0);
        if ($self->{uptime} =~ /\((\d+)\)/) {
          # Timeticks: (20718727) 2 days, 9:33:07.27
          $self->{uptime} = $1 / 100;
        } elsif ($self->{uptime} =~ /(\d+)\s*days.*(\d+):(\d+):(\d+)\.(\d+)/) {
          # Timeticks: 2 days, 9:33:07.27
          $self->{uptime} = $1 * 24 * 3600 + $2 * 3600 + $3 * 60 + $4;
        } elsif ($self->{uptime} =~ /(\d+):(\d+):(\d+)\.(\d+)/) {
          # Timeticks: 9:33:07.27
          $self->{uptime} = $1 * 3600 + $2 * 60 + $3;
        }
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
      }
      $self->{method} = 'snmp';
    }
  }
  if ($self->opts->blacklist &&
      -f $self->opts->blacklist) {
    $self->opts->blacklist = do {
        local (@ARGV, $/) = $self->opts->blacklist; <> };
  }
  $NWC::Device::statefilesdir = $self->opts->statefilesdir;
  return $self;
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
      $params{'-timeout'} = $self->opts->timeout;
      $params{'-hostname'} = $self->opts->hostname;
      $params{'-version'} = $self->opts->protocol;
      if ($self->opts->port) {
        $params{'-port'} = $self->opts->port;
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
        if (my $uptime = $self->get_snmp_object('MIB-II', 'sysUpTime', 0)) {
          $self->debug(sprintf 'snmp agent answered: %s', $uptime);
          $self->whoami();
        } else {
          $self->add_message(CRITICAL,
              'could not contact snmp agent');
          #$session->close;
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
  } else {
    $self->add_message(CRITICAL,
        'snmpwalk returns no product name (sysDescr)');
    if (! $self->opts->snmpwalk) {
      $NWC::Device::session->close;
    }
  }
  $self->debug('whoami: '.$self->{productname});
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

sub check_messages {
  my $self = shift;
  return $NWC::Device::plugin->check_messages(@_);
}

sub clear_messages {
  my $self = shift;
  return $NWC::Device::plugin->clear_messages(@_);
}

sub add_perfdata {
  my $self = shift;
  $NWC::Device::plugin->add_perfdata(@_);
}

sub set_thresholds {
  my $self = shift;
  $NWC::Device::plugin->set_thresholds(@_);
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
      my $toid = $NWC::Device::mibs_and_oids->{$mib}->{$table}.'.';
      my $toidlen = length($toid);
      my @columns = map {
          $NWC::Device::mibs_and_oids->{$mib}->{$_}
      } grep {
        substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $toidlen) eq
            $NWC::Device::mibs_and_oids->{$mib}->{$table}.'.'
      } keys %{$NWC::Device::mibs_and_oids->{$mib}};
      if ($augmenting_table && 
          exists $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}) {
        my $toid = $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}.'.';
        my $toidlen = length($toid);
        push(@columns, map {
            $NWC::Device::mibs_and_oids->{$mib}->{$_}
        } grep {
          substr($NWC::Device::mibs_and_oids->{$mib}->{$_}, 0, $toidlen) eq
              $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}.'.'
        } keys %{$NWC::Device::mibs_and_oids->{$mib}});
      }
      my $result = $self->get_entries(
          -startindex => $indices->[0]->[0],
          -endindex => $indices->[0]->[0],
          -columns => \@columns,
      );
      @entries = $self->make_symbolic($mib, $result, $indices);
    }
  } elsif (scalar(@{$indices}) > 1) {
    # man koennte hier pruefen, ob die indices aufeinanderfolgen
    # und dann get_entries statt get_table aufrufen
    if (exists $NWC::Device::mibs_and_oids->{$mib} &&
        exists $NWC::Device::mibs_and_oids->{$mib}->{$table}) {
      my $result = {};
      $result = $self->get_table(
          -baseoid => $NWC::Device::mibs_and_oids->{$mib}->{$table});
      if ($augmenting_table && 
          exists $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table}) {
        my $augmented_result = $self->get_table(
            -baseoid => $NWC::Device::mibs_and_oids->{$mib}->{$augmenting_table});
        map { $result->{$_} = $augmented_result->{$_} }
            keys %{$augmented_result};
      }
      # now we have numerical_oid+index => value
      # needs to become symboic_oid => value
      #my @indices = 
      #    $self->get_indices($NWC::Device::mibs_and_oids->{$mib}->{$entry});
      @entries = $self->make_symbolic($mib, $result, $indices);
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
  if (! $self->opts->snmpwalk) {
    my %newparams = ();
    $newparams{'-startindex'} = $params{'-startindex'}
        if defined $params{'-startindex'};
    $newparams{'-endindex'} = $params{'-endindex'}     
        if defined $params{'-startindex'};
    $newparams{'-columns'} = $params{'-columns'};
    $result = $NWC::Device::session->get_entries(%newparams);
    foreach my $key (keys %{$result}) {
      $self->add_rawdata($key, $result->{$key});
    }
  } else {
    my $preresult = $self->get_matching_oids(
        -columns => $params{'-columns'});
    foreach (keys %{$preresult}) {
      $result->{$_} = $preresult->{$_};
    }
    my @to_del = ();
    if ($params{'-startindex'}) {
      foreach my $resoid (keys %{$result}) {
        foreach my $oid (@{$params{'-columns'}}) {
          my $poid = $oid.'.';
          my $lpoid = length($poid);
          if (substr($resoid, 0, $lpoid) eq $poid) {
            my $oidpattern = $poid;
            $oidpattern =~ s/\./\\./g;
            if ($resoid =~ /^$oidpattern.(.+)$/) {
              if ($1 < $params{'-startindex'}) {
                push(@to_del, $oid);
              }
            }
          }
        }
      }
    }
    if ($params{'-endindex'}) {
      foreach my $resoid (keys %{$result}) {
        foreach my $oid (@{$params{'-columns'}}) {
          my $poid = $oid.'.';
          my $lpoid = length($poid);
          if (substr($resoid, 0, $lpoid) eq $poid) {
            my $oidpattern = $poid;
            $oidpattern =~ s/\./\\./g;
            if ($resoid =~ /^$oidpattern.(.+)$/) {
              if ($1 > $params{'-endindex'}) {
                push(@to_del, $oid);
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
  my $last_values = $self->load_state(%params) || eval {
    my $empty_events = {};
    foreach (@keys) {
      $empty_events->{$_} = 0;
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
    $last_values->{$_} = 0 if ! exists $last_values->{$_};
    if ($self->{$_} >= $last_values->{$_}) {
      $self->{'delta_'.$_} = $self->{$_} - $last_values->{$_};
    } else {
      # vermutlich db restart und zaehler alle auf null
      $self->{'delta_'.$_} = $self->{$_};
    }
    $self->debug(sprintf "delta_%s %f", $_, $self->{'delta_'.$_});
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
    if (! -d dirname($NWC::Device::statefilesdir)) {
      mkdir dirname($NWC::Device::statefilesdir);
    }
    mkdir $NWC::Device::statefilesdir;
  } elsif (! -w $NWC::Device::statefilesdir) {
    $self->schimpf();
  }
}

sub schimpf {
  my $self = shift;
  printf "statefilesdir %s is not writable.\nYou didn't run this plugin as root, didn't you?\n", $NWC::Device::statefilesdir;
}

sub save_state {
  my $self = shift;
  my %params = @_;
  my $extension = "";
  $self->create_statefilesdir();
  mkdir $NWC::Device::statefilesdir unless -d $NWC::Device::statefilesdir;
  my $statefile = sprintf "%s/%s_%s", 
      $NWC::Device::statefilesdir, $self->opts->hostname, $self->opts->mode;
  #$extension .= $params{differenciator} ? "_".$params{differenciator} : "";
  $extension .= $params{name} ? '_'.$params{name} : '';
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  $statefile .= $extension;
  $statefile = lc $statefile;
  open(STATE, ">$statefile");
  if ((ref($params{save}) eq "HASH") && exists $params{save}->{timestamp}) {
    $params{save}->{localtime} = scalar localtime $params{save}->{timestamp};
  } 
  printf STATE Data::Dumper::Dumper($params{save});
  close STATE; 
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($params{save}), $statefile);
}

sub load_state {
  my $self = shift;
  my %params = @_;
  my $extension = "";
  my $statefile = sprintf "%s/%s_%s", 
      $NWC::Device::statefilesdir, $self->opts->hostname, $self->opts->mode;
  #$extension .= $params{differenciator} ? "_".$params{differenciator} : "";
  $extension .= $params{name} ? '_'.$params{name} : '';
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  $statefile .= $extension;
  $statefile = lc $statefile;
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

;
