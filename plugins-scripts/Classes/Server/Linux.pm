package Server::Linux;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem('Server::Linux::Component::InterfaceSubsystem');
  }
}


package Server::Linux::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{interfaces} = [];
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (glob "/sys/class/net/*") {
      my $name = $_;
      next if ! -d $name;
      $name =~ s/.*\///g;
      my $tmpif = {
        ifDescr => $name,
      };
      push(@{$self->{interfaces}},
        Server::Linux::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
    }
  } else {
    foreach (glob "/sys/class/net/*") {
      my $name = $_;
      $name =~ s/.*\///g;
      if ($self->opts->name) {
        if ($self->opts->regexp) {
          my $pattern = $self->opts->name;
          if ($name !~ /$pattern/i) {
            next;
          }
        } elsif (lc $name ne lc $self->opts->name) {
          next;
        }
      }
      *SAVEERR = *STDERR;
      open ERR ,'>/dev/null';
      *STDERR = *ERR;
      my $tmpif = {
        ifDescr => $name,
        ifSpeed => (-f "/sys/class/net/$name/speed" ? do { local (@ARGV, $/) = "/sys/class/net/$name/speed"; my $x = <>; close ARGV; $x} * 1024*1024 : undef),
        ifInOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_bytes"; my $x = <>; close ARGV; $x},
        ifInDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_dropped"; my $x = <>; close ARGV; $x},
        ifInErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/rx_errors"; my $x = <>; close ARGV; $x},
        ifOutOctets => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_bytes"; my $x = <>; close ARGV; $x},
        ifOutDiscards => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_dropped"; my $x = <>; close ARGV; $x},
        ifOutErrors => do { local (@ARGV, $/) = "/sys/class/net/$name/statistics/tx_errors"; my $x = <>; close ARGV; $x},
      };
      *STDERR = *SAVEERR;
      foreach (keys %{$tmpif}) {
        chomp($tmpif->{$_}) if defined $tmpif->{$_};
      }
      if (defined $self->opts->ifspeed) {
        $tmpif->{ifSpeed} = $self->opts->ifspeed * 1024*1024;
      }
      if (! defined $tmpif->{ifSpeed}) {
        $self->add_unknown(sprintf "There is no /sys/class/net/%s/speed. Use --ifspeed", $name);
      } else {
        push(@{$self->{interfaces}},
          Server::Linux::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
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


package Server::Linux::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  foreach (qw(ifSpeed ifInOctets ifInDiscards ifInErrors ifOutOctets ifOutDiscards ifOutErrors)) {
    $self->{$_} = 0 if ! defined $self->{$_};
  }
  if ($self->mode =~ /device::interfaces::complete/) {
    # uglatto, but $self->mode is an lvalue
    $Monitoring::GLPlugin::mode = "device::interfaces::operstatus";
    $self->init();
    #if ($self->{ifOperStatus} eq "up") {
      foreach my $mode (qw(device::interfaces::usage
          device::interfaces::errors device::interfaces::discards)) {
        $Monitoring::GLPlugin::mode = $mode;
        $self->init();
      }
    #}
    $Monitoring::GLPlugin::mode = "device::interfaces::complete";
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInOctets ifOutOctets));
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
    if (defined $self->opts->ifspeed) {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->opts->ifspeedin);
      $self->{maxInputRate} = $self->opts->ifspeedin;
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
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInErrors ifOutErrors));
    $self->{inputErrorRate} = $self->{delta_ifInErrors}
        / $self->{delta_timestamp};
    $self->{outputErrorRate} = $self->{delta_ifOutErrors}
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::discards/) {
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
          device::interfaces::errors device::interfaces::discards)) {
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
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxInputRate},
        warning => $self->{maxInputRate} / 100 * $inwarning,
        critical => $self->{maxInputRate} / 100 * $incritical,
    );
    my ($outwarning, $outcritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxOutputRate},
        warning => $self->{maxOutputRate} / 100 * $outwarning,
        critical => $self->{maxOutputRate} / 100 * $outcritical,
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

