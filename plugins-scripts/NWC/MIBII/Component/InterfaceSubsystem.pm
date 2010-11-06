package NWC::MIBII::Component::InterfaceSubsystem;
our @ISA = qw(NWC::MIBII);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
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
  } else {
    $self->update_interface_cache(0);
    #next if $self->opts->can('name') && $self->opts->name && 
    #    $self->opts->name ne $_->{ifDescr};
    # if limited search
    # name is a number -> get_table with extra param
    # name is a regexp -> list of names -> list of numbers
    my @indices = $self->get_interface_indices();
    foreach ($self->get_snmp_table_objects(
        'MIB-II', 'ifTable', 'ifEntry', \@indices)) {
    #foreach ($self->get_table_entries(
    #    'MIB-II', 'ifTable', \@indices)) {
      push(@{$self->{interfaces}},
          NWC::MIBII::Component::InterfaceSubsystem::Interface->new(%{$_}));
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking interfaces');
  $self->blacklist('ff', '');
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (@{$self->{interfaces}}) {
      $_->list();
    }
  } else {
    if (scalar (@{$self->{interfaces}}) == 0) {
    } else {
      foreach (@{$self->{interfaces}}) {
        $_->check();
      }
    }
  }
}

sub update_interface_cache {
  my $self = shift;
  my $force = shift;
  my $statefile = lc sprintf "%s/%s_interface_cache",
      $NWC::Device::statefilesdir, $self->opts->hostname;
  my $update = time - 3600;
  if ($force || ! -f $statefile || ((stat $statefile)[9]) < ($update)) {
    $self->{interface_cache} = {};
    foreach ($self->get_table_entries( 'MIB-II', 'ifTable')) {
      $self->{interface_cache}->{$_->{ifDescr}} = $_->{ifIndex};
    }
    $self->save_interface_cache();
  }
  $self->load_interface_cache();
}

sub save_interface_cache {
  my $self = shift;
  mkdir $NWC::Device::statefilesdir unless -d $NWC::Device::statefilesdir;
  my $statefile = lc sprintf "%s/%s_interface_cache",
      $NWC::Device::statefilesdir, $self->opts->hostname;
  open(STATE, ">$statefile");
  printf STATE Data::Dumper::Dumper($self->{interface_cache});
  close STATE;
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($self->{interface_cache}), $statefile);
}

sub load_interface_cache {
  my $self = shift;
  mkdir $NWC::Device::statefilesdir unless -d $NWC::Device::statefilesdir;
  my $statefile = lc sprintf "%s/%s_interface_cache",
      $NWC::Device::statefilesdir, $self->opts->hostname;
  if ( -f $statefile) {
    our $VAR1;
    eval {
      require $statefile;
    };
    if($@) {
      printf "rumms\n";
    }
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    $self->{interface_cache} = $VAR1;
  }
}

sub get_interface_indices {
  my $self = shift;
  my @indices = ();
  if (! $self->opts->name) {
    return @indices;
  }
  foreach my $ifdescr (keys %{$self->{interface_cache}}) {
    if ($self->opts->name) {
      if ($self->opts->regexp) {
        if ($ifdescr =~ /$self->opts->name/i) {
          push(@indices, $self->{interface_cache}->{$ifdescr});
        }
      } else {
        if (lc $ifdescr eq lc $self->opts->name) {
          push(@indices, $self->{interface_cache}->{$ifdescr});
        }
      }
    } else {
      push(@indices, $self->{interface_cache}->{$ifdescr});
    }
  }
  return @indices;
}

sub dump {
  my $self = shift;
  foreach (@{$self->{interfaces}}) {
    $_->dump();
  }
}


package NWC::MIBII::Component::InterfaceSubsystem::Interface;
our @ISA = qw(NWC::MIBII::Component::InterfaceSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    ifTable => $params{ifTable},
    ifEntry => $params{ifEntry},
    ifIndex => $params{ifIndex},
    ifDescr => $params{ifDescr},
    ifType => $params{ifType},
    ifMtu => $params{ifMtu},
    ifSpeed => $params{ifSpeed},
    ifPhysAddress => $params{ifPhysAddress},
    ifAdminStatus => $params{ifAdminStatus},
    ifOperStatus => $params{ifOperStatus},
    ifLastChange => $params{ifLastChange},
    ifInOctets => $params{ifInOctets},
    ifInUcastPkts => $params{ifInUcastPkts},
    ifInNUcastPkts => $params{ifInNUcastPkts},
    ifInDiscards => $params{ifInDiscards},
    ifInErrors => $params{ifInErrors},
    ifInUnknownProtos => $params{ifInUnknownProtos},
    ifOutOctets => $params{ifOutOctets},
    ifOutUcastPkts => $params{ifOutUcastPkts},
    ifOutNUcastPkts => $params{ifOutNUcastPkts},
    ifOutDiscards => $params{ifOutDiscards},
    ifOutErrors => $params{ifOutErrors},
    ifOutQLen => $params{ifOutQLen},
    ifSpecific => $params{ifSpecific},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $key (keys %params) {
    $self->{$key} = 0 if ! defined $params{$key};
  }
  bless $self, $class;
  if ($self->mode =~ /device::interfaces::traffic/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInOctets ifInUcastPkts ifInNUcastPkts ifInDiscards ifInErrors ifInUnknownProtos ifOutOctets ifOutUcastPkts ifOutNUcastPkts ifOutDiscards ifOutErrors));
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInOctets ifOutOctets));
    $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
        ($self->{delta_timestamp} * $self->{ifSpeed});
    $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
        ($self->{delta_timestamp} * $self->{ifSpeed});
    $self->{inputRate} = $self->{delta_ifInOctets} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifOutOctets} / $self->{delta_timestamp};
    my $factor = 1/8; # default Bits
    if ($self->opts->units) {
      if ($self->opts->units eq "GB") {
        $factor = 1024 * 1024 * 1024;
      } elsif ($self->opts->units eq "MB") {
        $factor = 1024 * 1024;
      } elsif ($self->opts->units eq "KB") {
        $factor = 1024;
      } elsif ($self->opts->units eq "B") {
        $factor = 1;
      } elsif ($self->opts->units eq "Bit") {
        $factor = 1/8;
      }
    }
    $self->{inputRate} /= $factor;
    $self->{outputRate} /= $factor;
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInErrors ifOutErrors ifInDiscards ifOutDiscards));
    $self->{inputErrorRate} = $self->{delta_ifInErrors} 
        / $self->{delta_timestamp};
    $self->{outputErrorRate} = $self->{delta_ifOutErrors} 
        / $self->{delta_timestamp};
    $self->{inputDiscardRate} = $self->{delta_ifInDiscards} 
        / $self->{delta_timestamp};
    $self->{outputDiscardRate} = $self->{delta_ifOutDiscards} 
        / $self->{delta_timestamp};
    $self->{inputRate} = ($self->{delta_ifInErrors} + $self->{delta_ifInDiscards}) 
        / $self->{delta_timestamp};
    $self->{outputRate} = ($self->{delta_ifOutErrors} + $self->{delta_ifOutDiscards}) 
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
  }
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('if', $self->{ifIndex});
  if ($self->mode =~ /device::interfaces::traffic/) {
  } elsif ($self->mode =~ /device::interfaces::usage/) {
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
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    my $info = sprintf 'interface %s errors in:%.2f/s out:%.2f/s '.
        'discards in:%.2f/s out:%.2f/s',
        $self->{ifDescr},
        $self->{inputErrorRate} , $self->{outputErrorRate},
        $self->{inputDiscardRate} , $self->{outputDiscardRate};
    $self->add_info($info);
    $self->set_thresholds(warning => 1, critical => 10);
    my $in = $self->check_thresholds($self->{inputRate});
    my $out = $self->check_thresholds($self->{outputRate});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level, $info);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
    #rfc2863
    #(1)   if ifAdminStatus is not down and ifOperStatus is down then a
    #     fault condition is presumed to exist on the interface.
    #(2)   if ifAdminStatus is down, then ifOperStatus will normally also
    #     be down (or notPresent) i.e., there is not (necessarily) a
    #     fault condition on the interface.
    # --warning onu,anu
    # Admin: admindown,admin
    # Admin: --warning 
    #        --critical admindown
    # !ad+od  ad+!(od*on)
    # warn & warnbitfield
#    if ($self->opts->critical) {
#      if ($self->opts->critical =~ /^u/) {
#      } elsif ($self->opts->critical =~ /^u/) {
#      }
#    }
#    if ($self->{ifOperStatus} ne 'up') {
#      }
#    } 
    my $info = sprintf '%s is %s/%s',
        $self->{ifDescr}, $self->{ifOperStatus}, $self->{ifAdminStatus};
    $self->add_info($info);
    $self->add_message(OK, $info);
    if ($self->{ifOperStatus} eq 'down' && $self->{ifAdminStatus} ne 'down') {
      $self->add_message(CRITICAL, 
          sprintf 'fault condition is presumed to exist on %s',
          $self->{ifDescr});
    }
  }
}

sub list {
  my $self = shift;
  printf "%06d %s\n", $self->{ifIndex}, $self->{ifDescr};
}

sub dump {
  my $self = shift;
  printf "[IF_%s]\n", $self->{ifIndex};
  foreach (qw(ifIndex ifDescr ifType ifMtu ifSpeed ifPhysAddress ifAdminStatus ifOperStatus ifLastChange ifInOctets ifInUcastPkts ifInNUcastPkts ifInDiscards ifInErrors ifInUnknownProtos ifOutOctets ifOutUcastPkts ifOutNUcastPkts ifOutDiscards ifOutErrors ifOutQLen ifSpecific)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
#  printf "info: %s\n", $self->{info};
  printf "\n";
}

