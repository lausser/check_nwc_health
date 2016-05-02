package Server::SolarisLocal;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem('Server::SolarisLocal::Component::InterfaceSubsystem');
  }
}


package Server::SolarisLocal::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub packet_size {
  my $stats = shift;
  if (defined $stats->{opackets64} && $stats->{opackets64} != 0 && defined $stats->{obytes64}) {
    return int($stats->{obytes64} / $stats->{opackets64});
  } elsif (defined $stats->{ipackets64} && $stats->{ipackets64} != 0 && defined $stats->{rbytes64}) {
    return int($stats->{rbytes64} / $stats->{ipackets64});
  } elsif (defined $stats->{opackets} && $stats->{opackets} != 0 && defined $stats->{obytes}) {
    return int($stats->{obytes} / $stats->{opackets});
  } elsif (defined $stats->{ipackets} && $stats->{ipackets} != 0 && defined $stats->{rbytes}) {
    return int($stats->{rbytes} / $stats->{ipackets});
  } else {
    return 0;
  }
}

sub init {
  my $self = shift;
  $self->{kstat} = Sun::Solaris::Kstat->new();
  $self->{interfaces} = [];
  $self->{kstat_interfaces} = {};
  foreach my $module (keys %{$self->{kstat}}) {
    foreach my $instance (keys %{$self->{kstat}->{$module}}) {
      foreach my $name (keys %{$self->{kstat}->{$module}->{$instance}}) {
        next if $name !~ /^$module/;
        if (defined $self->{kstat}->{$module}->{$instance}->{$name}->{ifspeed} ||
            $module eq "lo") {
          if (! defined $self->{packet_size}) {
            my $packet_size = packet_size($self->{kstat}->{$module}->{$instance}->{$name});
            $self->{packet_size} = $packet_size if $packet_size;
          }
          if ($self->filter_name($name)) {
            $self->{kstat_interfaces}->{$name} =
                exists $self->{kstat}->{$module}->{$instance}->{mac} ?
                $self->{kstat}->{$module}->{$instance}->{mac} :
                $self->{kstat}->{$module}->{$instance}->{$name};
          }
        }
      }
    }
  }
  if ($self->mode =~ /device::interfaces::list/) {
    foreach my $name (keys %{$self->{kstat_interfaces}}) {
      my $tmpif = {
        ifDescr => $name,
      };
      push(@{$self->{interfaces}},
        Server::SolarisLocal::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
    }
  } else {
    foreach my $name (keys %{$self->{kstat_interfaces}}) {
      my $tmpif = {};
      my $stats = $self->{kstat_interfaces}->{$name};
      $tmpif->{ifDescr} = $name;
      $tmpif->{ifSnapTime} = $stats->{snaptime};
      $tmpif->{ifSnapTime} =~ s/\..*//g;
      if (defined $stats->{ifspeed}) {
        $tmpif->{ifSpeed} = $stats->{ifspeed};
      } elsif ($name =~ /^lo/) {
        $tmpif->{ifSpeed} = 10000000000; # assume 10GBit backplane
      }
      if (defined $stats->{rbytes64}) {
        $tmpif->{ifInOctets} = $stats->{rbytes64};
      } elsif (defined $stats->{rbytes}) {
        $tmpif->{ifInOctets} = $stats->{rbytes};
      } elsif (defined $stats->{ipackets} && $self->{packet_size}) {
        $tmpif->{ifInOctets} = $stats->{ipackets} * $self->{packet_size};
      } else {
        $tmpif->{ifInOctets} = 0;
      }
      if (defined $stats->{obytes64}) {
        $tmpif->{ifOutOctets} = $stats->{obytes64};
      } elsif (defined $stats->{obytes}) {
        $tmpif->{ifOutOctets} = $stats->{obytes};
      } elsif (defined $stats->{opackets} && $self->{packet_size}) {
        $tmpif->{ifOutOctets} = $stats->{opackets} * $self->{packet_size};
      } else {
        $tmpif->{ifOutOctets} = 0;
      }
      $tmpif->{ifInErrors} = defined $stats->{ierrors} ? $stats->{ierrors} : 0;
      $tmpif->{ifOutErrors} = defined $stats->{oerrors} ? $stats->{oerrors} : 0;
      $tmpif->{ifInDiscards} = 0;
      $tmpif->{ifOutDiscards} = 0;
      if (defined $self->opts->ifspeed) {
        $tmpif->{ifSpeed} = $self->opts->ifspeed * 1024*1024;
      }
      if (! defined $tmpif->{ifSpeed}) {
        $self->add_unknown(sprintf "There is no /sys/class/net/%s/speed. Use --ifspeed", $name);
      } else {
        push(@{$self->{interfaces}},
          Server::SolarisLocal::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
      }
    }
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking interfaces');
  if (scalar(@{$self->{interfaces}}) == 0) {
    $self->add_unknown('no interfaces');
    return;
  }
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (sort {$a->{ifDescr} cmp $b->{ifDescr}} @{$self->{interfaces}}) {
      $_->list();
    }
  } else {
    foreach (@{$self->{interfaces}}) {
      $_->check();
    }
  }
}

package Server::SolarisLocal::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  foreach (qw(ifSpeed ifInOctets ifInDiscards ifInErrors ifOutOctets ifOutDiscards ifOutErrors ifSnapTime)) {
    $self->{$_} = 0 if ! defined $self->{$_};
  }
  if ($self->mode =~ /device::interfaces::complete/) {
    # uglatto, but $self->mode is an lvalue
    $Monitoring::GLPlugin::mode = "device::interfaces::operstatus";
    $self->init();
    #if ($self->{ifOperStatus} eq "up") {
      foreach my $mode (qw(device::interfaces::usage
          device::interfaces::errors)) {
        $Monitoring::GLPlugin::mode = $mode;
        $self->init();
      }
    #}
    $Monitoring::GLPlugin::mode = "device::interfaces::complete";
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInOctets ifOutOctets ifSnapTime));
    $self->{delta_timestamp} = $self->{delta_ifSnapTime};
    $self->{delta_ifInBits} = $self->{delta_ifInOctets} * 8;
    $self->{delta_ifOutBits} = $self->{delta_ifOutOctets} * 8;
    if ($self->{ifSpeed} == 0) {
      # vlan graffl
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    } else {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{maxInputRate} = $self->{ifSpeed};
      $self->{maxOutputRate} = $self->{ifSpeed};
    }
    if (defined $self->opts->ifspeed) {
      $self->override_opt('ifspeedin', $self->opts->ifspeed);
      $self->override_opt('ifspeedout', $self->opts->ifspeed);
    }
    if (defined $self->opts->ifspeedin) {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->opts->ifspeedin);
      $self->{maxInputRate} = $self->opts->ifspeedin;
    }
    if (defined $self->opts->ifspeedout) {
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->opts->ifspeedout);
      $self->{maxOutputRate} = $self->opts->ifspeedout;
    }
    $self->{inputRate} = $self->{delta_ifInBits} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifOutBits} / $self->{delta_timestamp};
    $self->override_opt("units", "bit") if ! $self->opts->units;
    $self->{inputRate} /= $self->number_of_bits($self->opts->units);
    $self->{outputRate} /= $self->number_of_bits($self->opts->units);
    $self->{maxInputRate} /= $self->number_of_bits($self->opts->units);
    $self->{maxOutputRate} /= $self->number_of_bits($self->opts->units);
    if ($self->{ifOperStatus} eq 'down') {
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{inputRate} = 0;
      $self->{outputRate} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    }
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInErrors ifOutErrors ifSnapTime));
    $self->{delta_timestamp} = $self->{delta_ifSnapTime};
    $self->{inputErrorRate} = $self->{delta_ifInErrors}
        / $self->{delta_timestamp};
    $self->{outputErrorRate} = $self->{delta_ifOutErrors}
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /FORCENOTIMPLEMENTEDERROR::device::interfaces::discards/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInDiscards ifOutDiscards));
    $self->{inputDiscardRate} = $self->{delta_ifInDiscards}
        / $self->{delta_timestamp};
    $self->{outputDiscardRate} = $self->{delta_ifOutDiscards}
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
  }
  return $self;
}

sub check {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::complete/) {
    # uglatto, but $self->mode is an lvalue
    $Monitoring::GLPlugin::mode = "device::interfaces::operstatus";
    $self->check();
    #if ($self->{ifOperStatus} eq "up") {
      foreach my $mode (qw(device::interfaces::usage
          device::interfaces::errors)) {
        $Monitoring::GLPlugin::mode = $mode;
        $self->check();
      }
    #}
    $Monitoring::GLPlugin::mode = "device::interfaces::complete";
  } elsif ($self->mode =~ /device::interfaces::usage/) {
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
    $self->add_perfdata(
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
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->add_info(sprintf 'interface %s errors in:%.2f/s out:%.2f/s ',
        $self->{ifDescr},
        $self->{inputErrorRate} , $self->{outputErrorRate});
    $self->set_thresholds(warning => 1, critical => 10);
    my $in = $self->check_thresholds($self->{inputErrorRate});
    my $out = $self->check_thresholds($self->{outputErrorRate});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorRate},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorRate},
    );
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    $self->add_info(sprintf 'interface %s discards in:%.2f/s out:%.2f/s ',
        $self->{ifDescr},
        $self->{inputDiscardRate} , $self->{outputDiscardRate});
    $self->set_thresholds(warning => 1, critical => 10);
    my $in = $self->check_thresholds($self->{inputDiscardRate});
    my $out = $self->check_thresholds($self->{outputDiscardRate});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardRate},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardRate},
    );
  }
}

sub list {
  my $self = shift;
  printf "%s\n", $self->{ifDescr};
}

