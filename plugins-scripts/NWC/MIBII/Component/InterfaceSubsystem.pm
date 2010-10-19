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
    interface_indices => [],
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
  my $snmpwalk = $params{rawdata};
  my $oids = {
      ifTable => '1.3.6.1.2.1.2.2',
      ifEntry => '1.3.6.1.2.1.2.2.1',
      ifIndex => '1.3.6.1.2.1.2.2.1.1',
      ifDescr => '1.3.6.1.2.1.2.2.1.2',
      ifType => '1.3.6.1.2.1.2.2.1.3',
      ifMtu => '1.3.6.1.2.1.2.2.1.4',
      ifSpeed => '1.3.6.1.2.1.2.2.1.5',
      ifPhysAddress => '1.3.6.1.2.1.2.2.1.6',
      ifAdminStatus => '1.3.6.1.2.1.2.2.1.7',
      ifOperStatus => '1.3.6.1.2.1.2.2.1.8',
      ifLastChange => '1.3.6.1.2.1.2.2.1.9',
      ifInOctets => '1.3.6.1.2.1.2.2.1.10',
      ifInUcastPkts => '1.3.6.1.2.1.2.2.1.11',
      ifInNUcastPkts => '1.3.6.1.2.1.2.2.1.12',
      ifInDiscards => '1.3.6.1.2.1.2.2.1.13',
      ifInErrors => '1.3.6.1.2.1.2.2.1.14',
      ifInUnknownProtos => '1.3.6.1.2.1.2.2.1.15',
      ifOutOctets => '1.3.6.1.2.1.2.2.1.16',
      ifOutUcastPkts => '1.3.6.1.2.1.2.2.1.17',
      ifOutNUcastPkts => '1.3.6.1.2.1.2.2.1.18',
      ifOutDiscards => '1.3.6.1.2.1.2.2.1.19',
      ifOutErrors => '1.3.6.1.2.1.2.2.1.20',
      ifOutQLen => '1.3.6.1.2.1.2.2.1.21',
      ifSpecific => '1.3.6.1.2.1.2.2.1.22',
      ifAdminStatusValue => {
          1 => 'up',
          2 => 'down',
          3 => 'testing',
      },
      ifOperStatusValue => {
          1 => 'up',
          2 => 'down',
          3 => 'testing',
          4 => 'unknown',
          5 => 'dormant',
          6 => 'notPresent',
          7 => 'lowerLayerDown',
      },
  };
  # INDEX { ifIndex }
  my $index_cache = {};
  foreach ($self->get_entries($oids, 'ifEntry')) {
    next if $self->opts->can('name') && $self->opts->name && 
        $self->opts->name ne $_->{ifDescr};
    push(@{$self->{interfaces}},
        NWC::MIBII::Component::InterfaceSubsystem::Interface->new(%{$_}));
    $index_cache->{$_->{ifIndex}} = $_->{ifDescr};
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking interfaces');
  $self->blacklist('ff', '');
  if (scalar (@{$self->{interfaces}}) == 0) {
  } else {
    foreach (@{$self->{interfaces}}) {
      $_->check();
    }
  }
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
    runtime => $params{runtime},
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
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorRate},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardRate},
        uom => $self->opts->units,
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardRate},
        uom => $self->opts->units,
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

sub dump {
  my $self = shift;
  printf "[IF_%s]\n", $self->{ifIndex};
  foreach (qw(ifIndex ifDescr ifType ifMtu ifSpeed ifPhysAddress ifAdminStatus ifOperStatus ifLastChange ifInOctets ifInUcastPkts ifInNUcastPkts ifInDiscards ifInErrors ifInUnknownProtos ifOutOctets ifOutUcastPkts ifOutNUcastPkts ifOutDiscards ifOutErrors ifOutQLen ifSpecific)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

