package NWC::Device;

use strict;
use IO::File;
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
    $self->check_snmp_and_model();
    if ($self->opts->servertype) {
      $self->{productname} = 'cisco' if $self->opts->servertype eq 'cisco';
      $self->{productname} = 'huawei' if $self->opts->servertype eq 'huawei';
      $self->{productname} = 'hp' if $self->opts->servertype eq 'hp';
    }
    if (! $NWC::Device::plugin->check_messages()) {
      if ($self->{productname} =~ /Cisco/i) {
        bless $self, 'NWC::Cisco';
        $self->trace(3, 'using NWC::Cisco');
      } else {
        $self->add_message(CRITICAL,
            sprintf('unknown device%s', $self->{productname} eq 'unknown' ?
                '' : '('.$self->{productname}.')'));
      }
      $self->{method} = 'snmp';
    }
  }
  if ($self->opts->blacklist &&
      -f $self->opts->blacklist) {
    $self->opts->blacklist = do {
        local (@ARGV, $/) = $self->opts->blacklist; <> };
  }
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
      open(MESS, $self->opts->snmpwalk);
      while(<MESS>) {
        # SNMPv2-SMI::enterprises.232.6.2.6.7.1.3.1.4 = INTEGER: 6
        if (/^([\d\.]+) = .*?: (\-*\d+)/) {
          $response->{$1} = $2;
        } elsif (/^([\d\.]+) = .*?: "(.*?)"/) {
          $response->{$1} = $2;
          $response->{$1} =~ s/\s+$//;
        } elsif (/^([\d\.]+) = .*?: (.*)/) {
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
    $self->set_rawdata($response);
    $self->whoami();
  } else {
    if (eval "require Net::SNMP") {
      my %params = ();
      my $net_snmp_version = Net::SNMP->VERSION(); # 5.002000 or 6.000000
      #$params{'-translate'} = [
      #  -all => 0x0
      #];
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
        $self->add_message(CRITICAL, 'cannot create session object');
        $self->trace(1, Data::Dumper::Dumper(\%params));
      } else {
        $NWC::Device::session = $session;
        my $sysUpTime = '1.3.6.1.2.1.1.3.0';
        my $result = $self->get_request(
            -varbindlist => [$sysUpTime]
        );
        if (!defined($result)) {
          $self->add_message(CRITICAL,
              'could not contact snmp agent');
          $session->close;
        } else {
          $self->trace(3, 'snmp agent answered');
          $self->whoami();
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
  if ($self->opts->snmpwalk) {
    my $sysDescr = '1.3.6.1.2.1.1.1.0';
$self->{rawdata}->{$sysDescr} = "bla cisco";
    if ($productname = $self->rawdata->{$sysDescr}) {
      if (! $productname) {
        $self->{productname} = 'Cisco';
      } else {
        $self->{productname} = $self->rawdata->{$sysDescr};
      }
    } else {
      $self->add_message(CRITICAL,
          'snmpwalk returns no product name (cpqsinfo-mib)');
    }
  } else {
    my $sysDescr = '1.3.6.1.2.1.1.1.0';
    my $dummy = '1.3.6.1.2.1.1.5.0';
    if ($productname = $self->valid_response($sysDescr)) {
      if ($productname eq '') {
        $self->{productname} = 'Cisco';
      } else {
        $self->{productname} = $productname;
      }
    } else {
      $self->add_message(CRITICAL,
          'snmpwalk returns no product name (cpqsinfo-mib)');
      $self->{session}->close;
    }
    $self->trace(3, 'whoami: '.$self->{productname});
  }
}

sub valid_response {
  my $self = shift;
  my $oid = shift;
  my $result = $NWC::Device::session->get_request(
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
}

sub debug {
  my $self = shift;
  my $msg = shift;
#    printf "%s %s\n", $msg, ref($self);
}

sub trace {
  my $self = shift;
  my $format = shift;
return;
  $self->{trace} = -f "/tmp/check_nwc_health.trace" ? 1 : 0;
  if ($self->opts->verbose) {
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

sub get_request {
  my $self = shift;
  my %params = @_;
  my @notcached = ();
  if (exists $params{'-varbindlist'}) {
    foreach my $oid (@{$params{'-varbindlist'}}) {
      if (! exists NWC::Device::rawdata->{$oid}) {
        my $result = $NWC::Device::session->get_request(
          -varbindlist => $oid
        );
        foreach my $key (%{$result}) {
          $self->add_rawdata($key, $result->{$key});
        }
      }
    }
    my $result = {};
    map { $result->{$_} = $NWC::Device::rawdata->{$_} }
        @{$params{'-varbindlist'}};
    return $result;
  }
  return {};
}

sub get_table {
  my $self = shift;
  return $NWC::Device::session->get_table(@_);
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
    if ($self->opts->can('lookback')) {
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
    if ($self->opts->can('lookback')) {
      $empty_events->{lookback_history} = $last_values->{lookback_history};
      foreach (@keys) {
        $empty_events->{lookback_history}->{$_}->{$now} = $self->{$_};
      }
    }
    $empty_events;
  };
  $self->save_state(%params);
}

sub save_state {
  my $self = shift;
  my %params = @_;
  my $extension = "";
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


sub get_entries {
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
  my $entry = shift;
  my $numindices = shift;
  # find all oids beginning with $entry
  # then skip one field for the sequence
  # then read the next numindices fields
  my $entrypat = $entry;
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

1;
