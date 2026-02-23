package CheckNwcHealth::Cisco::Viptela::Component::SdwanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode eq "device::sdwan::control::vedgecount") {
    # lookback is in hours
    $self->override_opt("lookback", 24*7) if ! $self->opts->lookback;
    $self->get_snmp_tables('VIPTELA-SECURITY', [
        ["ctrlsummaries", "controlSummaryTable", "CheckNwcHealth::Cisco::Viptela::Component::SdwanSubsystem::ControlSummary", sub { my ($o) = @_;; return $self->filter_name($o->{controlSummaryInstance}); }],
    ]);
  } elsif ($self->mode eq "device::sdwan::control::connections" or
      $self->mode eq "device::sdwan::management::connections") {
    $self->get_snmp_tables("VIPTELA-SECURITY", [
      ["ctlconns", "controlConnectionsTable", "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ControlConnection", undef, ["controlConnectionsPeerType", "controlConnectionsSystemIp", "controlConnectionsLocalColor", "controlConnectionsState"]],
    ]);
  } else {
    $self->no_such_mode();
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode eq "device::sdwan::control::vedgecount") {
    if (! @{$self->{ctrlsummaries}}) {
      $self->add_unknown_mitigation("this device does not have controlSummary entries");
    } else {
      $self->SUPER::check();
    }
  } elsif ($self->mode =~ /device::sdwan::(control|management)::connections/) {
    if (! @{$self->{ctlconns}}) {
      $self->add_unknown("did not find any control connections");
    } else {
      my $num_connections = 0;
      my $num_up_connections = 0;
      my $num_connections_vmanage = 0;
      my $num_up_connections_vmanage = 0;
      my $num_connections_vsmart = {};
      my $num_up_connections_vsmart = {};
      foreach my $connection (@{$self->{ctlconns}}) {
        my $state = $connection->{controlConnectionsState};
        my $color = $connection->{controlConnectionsLocalColor};
        my $type = $connection->{controlConnectionsPeerType};
        $num_connections++;
        if ($state eq "up") {
          $num_up_connections++;
        }
        if ($type eq "vmanage") {
          $num_connections_vmanage++;
          $num_up_connections_vmanage++ if $state eq "up";
        }
        if ($type eq "vsmart") {
          $num_connections_vsmart->{$color} = 0 if not
              exists $num_connections_vsmart->{$color};
          $num_up_connections_vsmart->{$color} = 0 if not
              exists $num_up_connections_vsmart->{$color};
          $num_connections_vsmart->{$color}++;
          $num_up_connections_vsmart->{$color}++ if $state eq "up";
        }
      }
      # VMANAGE steht 1x in der Zentrale, macht Softwareupdates, seltene Sachen
      #  kann schon mal weg sein, sollte aber nicht.
      # VSMART steht 2x in der Zentrale. Von hier aus werden die Router im SDWAN
      #  konfigmaessig aktualisiert, d.h. alle Netzweraenderungen, Rerouting, Failover..
      #  werden von hier aus gesteuert. Ohne Verbindung von VSMART zu einem Router sind
      #  keine Aenderungen im Netzwerk (Software-Defined) mehr moeglich. Der Router
      #  routet dann wie ein bloeder Router.
      if ($self->mode eq "device::sdwan::control::connections") {
        # SDWAN Controller-Connect Status:
        # Mindestens eine controlConnectionsState ist down => Warning
        # Zwei controlConnectionsState desselben
        # controlConnectionsLocalColor (MPLS, PUBLIC-INTERNET oder
        #   BIZ-INTERNET) und vom controlConnectionsPeerType = VSMART
        #   sind down => Critical
        if ($num_connections > $num_up_connections) {
          $self->add_warning(sprintf "only %d of %d control connections are up", $num_up_connections, $num_connections);
        } else {
          $self->add_ok(sprintf "%d of %d control connections are up", $num_up_connections, $num_connections);
        }
        foreach my $color (keys %{$num_connections_vsmart}) {
          if ($num_connections_vsmart->{$color} - $num_up_connections_vsmart->{$color} >= 2) {
            $self->add_critical(sprintf "only %d of %d %s/vsmart control connections are up", $num_up_connections_vsmart->{$color}, $num_connections_vsmart->{$color}, $color);
          }
        }
      } elsif ($self->mode eq "device::sdwan::management::connections") {
        # SDWAN MGMT-Connect status:
        # Alle controlConnectionsState vom
        #   controlConnectionsPeerType = VMANAGE sind down => Critical
        if ($num_connections_vmanage) {
          if ($num_up_connections_vmanage) {
            $self->add_ok(sprintf "%d of %d vmanage control connections are up", $num_up_connections_vmanage, $num_connections_vmanage);
          } else {
            $self->add_critical("none of the vmanage control connections is up");
          }
        } else {
          $self->add_unknown("no control connections of type vmanage were found");
        }
      }
    }
  } else {
    $self->SUPER::check();
  }
}

package CheckNwcHealth::Cisco::Viptela::Component::SdwanSubsystem::ControlSummary;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


sub finish {
  my ($self) = @_;
  $self->{controlSummaryInstance} = $self->{flat_indices};
  if (! defined $self->{controlSummaryVedgeCounts}) {
    $self->{valid} = 0;
    return;
  } else {
    $self->{valid} = 1;
  }
}

sub calc {
  my ($self) = @_;
  my $now = time;
  # --lookback <hours>
  my $lookback_seconds = 3600 * $self->opts->lookback;
  my $laststate = $self->load_state(name => 'csvedgecount_'.$self->{flat_indices}) || {
      values_with_timestamps => [],
  };
  # Remove outdated entries that are outside the lookback window
  while (@{$laststate->{values_with_timestamps}} && $laststate->{values_with_timestamps}->[0]->{time} < $now - $lookback_seconds) {
    shift @{$laststate->{values_with_timestamps}};
  }
  # Calculate the mean
  my $sum = 0;
  foreach (@{$laststate->{values_with_timestamps}}) {
    $sum += $_->{value};
  }
  my $count = scalar @{$laststate->{values_with_timestamps}};
  my $mean = $count > 0 ? $sum / $count : 0;
  # Calculate the standard deviation
  my $variance_sum = 0;
  foreach (@{$laststate->{values_with_timestamps}}) {
    $variance_sum += ($_->{value} - $mean) ** 2;
  }
  my $variance = $count > 1 ? $variance_sum / ($count - 1) : 0;
  my $std_dev = sqrt($variance);
  $self->{mean_value} = $mean;
  $self->{mean_base} = $count;
  $self->{std_dev} = $std_dev;
  $self->{z_score} = $self->{std_dev} > 0 ?
      ($self->{controlSummaryVedgeCounts} - $self->{mean_value}) /
          $self->{std_dev} : 0;
  push @{$laststate->{values_with_timestamps}}, {
      value => $self->{controlSummaryVedgeCounts}, time => $now
  };
  $self->save_state(name => 'csvedgecount_'.$self->{flat_indices}, save => {
      values_with_timestamps => $laststate->{values_with_timestamps},
  });

  # Estimate the check_interval
  my $bucket_size = 10; # 10s delay from check_interval
  my %bucket_count;
  my $prev_time = $laststate->{values_with_timestamps}->[0]->{time};
  for (my $i = 1; $i < @{$laststate->{values_with_timestamps}}; $i++) {
    my $curr_time = $laststate->{values_with_timestamps}->[$i]->{time};
    my $delta += ($curr_time - $prev_time);
    $prev_time = $curr_time;
    my $bucket = int($delta / $bucket_size) * $bucket_size;
    $bucket_count{$bucket}++;
  }
  if (%bucket_count) {
    $self->{check_interval} = (sort { $bucket_count{$b} <=> $bucket_count{$a} } keys %bucket_count)[0];
  } else {
    $self->{check_interval} = 0;
  }
}

sub check {
  my ($self) = @_;
  if (! $self->{valid}) {
    $self->add_unknown_mitigation(
        sprintf "control summary #%s does not have controlSummaryVedgeCounts",
        $self->{flat_indices}
    );
    return;
  }
  $self->calc();
  my $time_range = $self->{check_interval} * $self->{mean_base};
  if ($time_range <= 3600 * $self->opts->lookback / 2) {
    # wenigstens die Haelfte des Basiszeitraums fuer den Vergleich sollte
    # mit Messungen abgedeckt sein.
    $self->add_info(
        sprintf "no sufficient data collected for #%s in the last %s",
        $self->{flat_indices},
        $self->human_timeticks($time_range));
    $self->add_ok();
    return;
  }

  $self-> add_info(sprintf "index %s last measurement %d has a z-score of %.2f. mean is %.2f based on %d measurements. std_dev is %.2f",
      $self->{flat_indices},
      $self->{controlSummaryVedgeCounts},
      $self->{z_score},
      $self->{mean_value},
      $self->{mean_base},
      $self->{std_dev});
  $self->set_thresholds(
      metric => 'z_score_'.$self->{flat_indices},
      warning => "-2:2",
      critical => "-3:3",
  );
  $self->add_message($self->check_thresholds(
      metric => 'z_score_'.$self->{flat_indices},
      value => $self->{z_score},
  ));
  $self->add_perfdata(
    label => 'z_score_'.$self->{flat_indices},
    value => $self->{z_score},
  );
  $self->add_perfdata(
    label => 'mean_'.$self->{flat_indices},
    value => $self->{mean_value},
  );
  $self->add_perfdata(
    label => 'std_dev_'.$self->{flat_indices},
    value => $self->{std_dev},
  );
}

1;
