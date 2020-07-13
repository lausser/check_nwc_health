package Classes::F5::F5BIGIP::Component::VipSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use Socket;
use Net::Ping;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-BIGIP-LOCAL-MIB', [
      ['vips', 'ltmVirtualServTable', 'Classes::F5::F5BIGIP::Component::VipSubsystem::VIP'],
  ]);
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /vip::list/) {
    foreach (@{$self->{vips}}) {
      printf "%s\n", $_->{ltmVirtualServName};
    }
    $self->add_ok("have fun");
  } elsif ($self->mode =~ /vip::connect/) {
    my $ping = Net::Ping->new("syn");
    foreach (@{$self->{vips}}) {
      $ping->port_number($_->{ltmVirtualServPort});
      my $now = time;
      $ping->ping_syn($_->{ltmVirtualServAddr},
          inet_aton($_->{ltmVirtualServAddr}),
          $now, $now + 2);
    }
    sleep 1;
    my $num_unreachable_vips = 0;
    foreach (@{$self->{vips}}) {
      $ping->port_number($_->{ltmVirtualServPort});
      if ($ping->ack($_->{ltmVirtualServAddr})) {
        $self->add_info(sprintf "%s:%d reachable",
            $_->{ltmVirtualServName}, $_->{ltmVirtualServPort});
        $self->add_ok();
      } else {
        $num_unreachable_vips++;
        my $host = $self->reverse_resolve($_->{ltmVirtualServAddr});
        if ($host) {
          $self->add_info(sprintf "%s:%d (%s) unreachable",
              $_->{ltmVirtualServName}, $_->{ltmVirtualServPort}, $host);
        } else {
          $self->add_info(sprintf "%s:%d unreachable",
              $_->{ltmVirtualServName}, $_->{ltmVirtualServPort});
        }
        $self->add_critical();
      }
    }
    $self->reduce_messages(sprintf "all %d vips are up", scalar(@{$self->{vips}}));
    $self->add_perfdata(
        label => 'reachable_vips',
        value => scalar(@{$self->{vips}}) - $num_unreachable_vips,
        min => 0,
        max => scalar(@{$self->{vips}}),
    );
    $self->add_perfdata(
        label => 'unreachable_vips',
        value => $num_unreachable_vips,
        min => 0,
        max => scalar(@{$self->{vips}}),
    );
  } elsif ($self->mode =~ /vip::watch/) {
    # take a snapshot of the vip list. -> good baseline
    # warning if there appear vips, mitigate to ok
    # critical if warn/crit percent disappear
    $self->{numOfVips} = scalar (@{$self->{vips}});
    $self->{vipNameList} = [map { $_->{ltmVirtualServName} } @{$self->{vips}}];
    $self->opts->override_opt('lookback', 3600) if ! $self->opts->lookback;
    if ($self->opts->reset) {
      my $statefile = $self->create_statefile(name => 'ltmviplist', lastarray => 1);
      unlink $statefile if -f $statefile;
    }
    $self->valdiff({name => 'ltmviplist', lastarray => 1},
        qw(vipNameList numOfVips));
    my $problem = 0;
    if ($self->opts->warning || $self->opts->critical) {
      $self->set_thresholds(warning => $self->opts->warning,
          critical => $self->opts->critical);
      my $before = $self->{numOfVips} - scalar(@{$self->{delta_found_vipNameList}}) + scalar(@{$self->{delta_lost_vipNameList}});
      # use own delta_numOfVips, because the glplugin version treats
      # negative deltas as overflows
      $self->{delta_numOfVips} = $self->{numOfVips} - $before;
      if ($self->opts->units && $self->opts->units eq "%") {
        my $delta_pct = $before ? (($self->{delta_numOfVips} / $before) * 100) : 0;
        $self->add_message($self->check_thresholds($delta_pct),
          sprintf "%.2f%% delta, before: %d, now: %d", $delta_pct, $before, $self->{numOfVips});
        $problem = $self->check_thresholds($delta_pct);
      } else {
        $self->add_message($self->check_thresholds($self->{delta_numOfVips}),
          sprintf "%d delta, before: %d, now: %d", $self->{delta_numOfVips}, $before, $self->{numOfVips});
        $problem = $self->check_thresholds($self->{delta_numOfVips});
      }
      if (scalar(@{$self->{delta_found_vipNameList}}) > 0) {
        $self->add_ok(sprintf 'found: %s',
            join(", ", @{$self->{delta_found_vipNameList}}));
      }
      if (scalar(@{$self->{delta_lost_vipNameList}}) > 0) {
        $self->add_ok(sprintf 'lost: %s',
            join(", ", @{$self->{delta_lost_vipNameList}}));
      }
    } else {
      if (scalar(@{$self->{delta_found_vipNameList}}) > 0) {
        $self->add_warning(sprintf '%d new vips (%s)',
            scalar(@{$self->{delta_found_vipNameList}}),
            join(", ", @{$self->{delta_found_vipNameList}}));
        $problem = 1;
      }
      if (scalar(@{$self->{delta_lost_vipNameList}}) > 0) {
        $self->add_critical(sprintf '%d vips missing (%s)',
            scalar(@{$self->{delta_lost_vipNameList}}),
            join(", ", map {
              my $vip = $_;
              my $name =  undef;
              if ($vip =~ /(\d+)[\.\-_](\d+)[\.\-_](\d+)[\.\-_](\d+)/) {
                if ($1 < 255 && $2 < 255 && $3 < 255 && $4 < 255) {
                  $name = $self->reverse_resolve($1.".".$2.".".$3.".".$4);
                }
              }
              if ($name) {
                $vip." (".$name.")";
              } else {
                $vip;
              }
            } @{$self->{delta_lost_vipNameList}}));
        $problem = 2;
      }
      $self->add_ok(sprintf 'found %d vips', scalar (@{$self->{vips}}));
    }
    if ($problem) { # relevant only for lookback=9999 and support contract customers
      $self->valdiff({name => 'ltmviplist', lastarray => 1, freeze => 1},
          qw(vipNameList numOfVips));
    } else {
      $self->valdiff({name => 'ltmviplist', lastarray => 1, freeze => 2},
          qw(vipNameList numOfVips));
    }
    $self->add_perfdata(
        label => 'num_vips',
        value => scalar (@{$self->{vips}}),
    );
  }
}

sub reverse_resolve {
  my ($self, $ip) = @_;
  my $name = undef;
  eval {
      $ENV{RES_OPTIONS} = "timeout:2";
      my $iaddr = Socket::inet_aton($ip);
      $name  = gethostbyaddr($iaddr, Socket::AF_INET);
  };
  return $name;
}

package Classes::F5::F5BIGIP::Component::VipSubsystem::VIP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
}

