package Classes::Cisco::CISCORTTMONMIB::Component::RttSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;


sub init {
  my ($self) = @_;
  $self->get_snmp_tables("CISCO-RTTMON-MIB", [
      ['rttmons', 'rttMonCtrlAdminTable+rttMonCtrlOperTable', 'Classes::Cisco::CISCORTTMONMIB::Component::RttSubsystem::Probe'],
      ['lastrtts', 'rttMonLatestRttOperTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
      ['rttechos', 'rttMonEchoAdminTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
      ['latestjitters', 'rttMonLatestJitterOperTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  # bei manchen geraeten kommt nach SNMPv2-SMI::enterprises.9.9.42.1.3.3.1.2
  # nichts mehr. (nach rttMonStatsTotalsTable)
  $self->merge_tables("rttmons", ("lastrtts", "rttechos", "latestjitters"));
  @{$self->{rttmons}} = grep {
    $self->filter_name($_->{name});
  } map {
    $_->_finish(); $_;
  } grep {
    ($_->{rttMonCtrlAdminRttType} =~ /^(echo|pathEcho|jitter)$/) ? 1 : 0;
  } @{$self->{rttmons}};
}


package Classes::Cisco::CISCORTTMONMIB::Component::RttSubsystem::LatestJitter;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
}

sub check {
  my ($self) = @_;
}


package Classes::Cisco::CISCORTTMONMIB::Component::RttSubsystem::Probe;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub _finish {
  # kein finish(), da erst merge_tables laufen muss
  my ($self) = @_;
  $self->{rttMonEchoAdminSourceAddress} =
      $self->unhex_ip($self->{rttMonEchoAdminSourceAddress});
  $self->{rttMonEchoAdminTargetAddress} =
      $self->unhex_ip($self->{rttMonEchoAdminTargetAddress});
  if ($self->{rttMonCtrlAdminLongTag}) {
    $self->{name} = $self->{rttMonCtrlAdminLongTag}
  } elsif ($self->{rttMonCtrlAdminTag}) {
    $self->{name} = $self->{rttMonCtrlAdminTag}
  } elsif ($self->{rttMonEchoAdminTargetAddress}) {
    $self->{name} = "target_".$self->{rttMonEchoAdminTargetAddress}
  } else {
    $self->{name} = $self->{flat_indices};
  }
  if (defined $self->{rttMonLatestJitterOperNumOfRTT}) {
    # War ja klar, dass in irgendeiner Besenkammer noch so alte Kisten
    # rumstehen, die keine 64bittige RTTSum kennen.
    # Cisco Internetwork Operating System Software ^M IOS (tm) GS Software (C12KPRP-K4P-M), Version 12.0(32)SY7, RELEASE SOFTWARE (fc1)^M Technical Support: http://www.cisco.com/techsupport^M Copyright (c) 1986-2008 by cisco Systems, Inc.^M Compiled Mon 29-Sep-08
    $self->{rttMonLatestJitterOperRTTSumHigh} ||= 0;
    $self->{rttMonLatestJitterOperRTTSum2High} ||= 0;
    #
    $self->{rttMonLatestJitterOperRTTSum} =
        $self->{rttMonLatestJitterOperRTTSum} +
        ($self->{rttMonLatestJitterOperRTTSumHigh} << 32);
    $self->{rttMonLatestJitterOperRTTSum2} =
        $self->{rttMonLatestJitterOperRTTSum2} +
        ($self->{rttMonLatestJitterOperRTTSum2High} << 32);
    $self->{rttMonLatestJitterAvgRTT} =
        $self->{rttMonLatestJitterOperNumOfRTT} ?
        $self->{rttMonLatestJitterOperRTTSum} /
            $self->{rttMonLatestJitterOperNumOfRTT} : 0;
    $self->{rttMonLatestJitterVarianceRTT} =
        $self->{rttMonLatestJitterOperNumOfRTT} > 1 ?
        $self->{rttMonLatestJitterOperRTTSum2} /
            ($self->{rttMonLatestJitterOperNumOfRTT} - 1) : 0;
    $self->{rttMonLatestJitterStdDevRTT} =
        $self->{rttMonLatestJitterOperNumOfRTT} > 1 ?
        sqrt($self->{rttMonLatestJitterOperRTTSum2} /
            ($self->{rttMonLatestJitterOperNumOfRTT} - 1)) : 0;
    $self->{rttMonLatestJitterOperMOS} /= 100;
    # https://en.wikipedia.org/wiki/Mean_opinion_score
    # Rating Label 
    # 5      Excellent 
    # 4      Good 
    # 3      Fair 
    # 2      Poor 
    # 1      Bad 
    $self->{rttMonLatestJitterOperAvgPositivesSD} =
        $self->{rttMonLatestJitterOperNumOfPositivesSD} ?
        $self->{rttMonLatestJitterOperSumOfPositivesSD} /
        $self->{rttMonLatestJitterOperNumOfPositivesSD} : 0;
    $self->{rttMonLatestJitterOperAvgNegativesSD} =
        $self->{rttMonLatestJitterOperNumOfNegativesSD} ?
        -1 * $self->{rttMonLatestJitterOperSumOfNegativesSD} /
        $self->{rttMonLatestJitterOperNumOfNegativesSD} : 0;
    $self->{rttMonLatestJitterOperAvgPositivesDS} =
        $self->{rttMonLatestJitterOperNumOfPositivesDS} ?
        $self->{rttMonLatestJitterOperSumOfPositivesDS} /
        $self->{rttMonLatestJitterOperNumOfPositivesDS} : 0;
    $self->{rttMonLatestJitterOperAvgNegativesDS} =
        $self->{rttMonLatestJitterOperNumOfNegativesDS} ?
        - 1 * $self->{rttMonLatestJitterOperSumOfNegativesDS} /
        $self->{rttMonLatestJitterOperNumOfNegativesDS} : 0;
    $self->{rttMonLatestJitterOperPacketLossCount} =
        $self->{rttMonLatestJitterOperPacketLossSD} +
        $self->{rttMonLatestJitterOperPacketLossDS} +
        $self->{rttMonLatestJitterOperPacketMIA};
  }
}

sub check {
  my ($self) = @_;
  if ($self->{rttMonCtrlOperState} ne "active") {
    $self->add_info(sprintf "%s probe %s has oper status %s",
        $self->{rttMonCtrlAdminRttType}, 
        $self->{name}, 
        $self->{rttMonCtrlOperState}, 
    );
    $self->add_unknown();
    return;
  }
  if ($self->{rttMonCtrlAdminRttType} eq "jitter") {
    $self->add_info(sprintf "%s probe %s (target %s, codec %s) has status %s",
        $self->{rttMonCtrlAdminRttType}, 
        $self->{name}, 
        $self->{rttMonEchoAdminTargetAddress},
        $self->{rttMonEchoAdminCodecType},
        $self->{rttMonLatestRttOperSense});
  } else {
    $self->add_info(sprintf "%s probe %s has status %s",
        $self->{rttMonCtrlAdminRttType},
        $self->{name}, 
        $self->{rttMonLatestRttOperSense});
  }
  if ($self->{rttMonCtrlOperConnectionLostOccurred} eq "true") {
    $self->add_info(sprintf "%s probe %s lost connection",
        $self->{rttMonCtrlAdminRttType}, 
        $self->{name}, 
    );
    $self->add_warning();
    return;
  }
  if ($self->{rttMonCtrlOperOverThresholdOccurred} eq "true") {
    $self->add_info(sprintf "%s probe %s is over threshold",
        $self->{rttMonCtrlAdminRttType}, 
        $self->{name}, 
    );
    $self->add_warning();
    return;
  }
  if ($self->{rttMonCtrlOperTimeoutOccurred} eq "true") {
    $self->add_info(sprintf "%s probe %s timed out",
        $self->{rttMonCtrlAdminRttType}, 
        $self->{name}, 
    );
    $self->add_warning();
    return;
  }
  if ($self->{rttMonCtrlOperVerifyErrorOccurred} eq "true") {
    $self->add_info(sprintf "%s probe %s shows data corruption",
        $self->{rttMonCtrlAdminRttType}, 
        $self->{name}, 
    );
    $self->add_warning();
    return;
  }
  if ($self->{rttMonCtrlAdminRttType} eq "jitter") {
    $self->check_jitter();
  }
  $self->add_ok() if ! $self->check_messages();
}

sub check_jitter {
  my ($self) = @_;
  if ($self->{rttMonLatestRttOperSense} eq "ok") {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  my $label = $self->{name}."_".$self->{rttMonCtrlAdminRttType}."_rtt_completion_time";
  $self->add_perfdata(label =>
      $label,
      value => $self->{rttMonLatestRttOperCompletionTime},
      uom => "ms",
  );

  if (defined $self->{rttMonLatestJitterOperNumOfRTT}) {
    $self->add_info(sprintf "%s latest jitter status is %s",
        $self->{name},
        $self->{rttMonLatestJitterOperSense}
    );
    if ($self->{rttMonLatestJitterOperSense} ne "ok") {
      $self->add_critical();
    }
  
    if ($self->{rttMonLatestJitterOperNTPState} ne "sync") {
      $self->add_warning(sprintf "%s NTP not in sync", $self->{name});
    }
  
    $label = $self->{name}."_"."latest_jitter_rtt_avg";
    $self->add_info(sprintf "average jitter RTT was %.2fms",
        $self->{rttMonLatestJitterAvgRTT},
    );
    $self->set_thresholds(metric => $label,
        warning => "",
        critical => 5000,
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterAvgRTT}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterAvgRTT},
        uom => "ms",
        min => $self->{rttMonLatestJitterOperRTTMin},
        max => $self->{rttMonLatestJitterOperRTTMax},
    );
    $label = $self->{name}."_"."latest_jitter_rtt_variance";
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterVarianceRTT},
    );
    $label = $self->{name}."_"."latest_jitter_rtt_stddev";
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterStdDevRTT},
    );
  
    $label = $self->{name}."_"."jitter_mos";
    $self->add_info(sprintf "MOS value was %.2f",
        $self->{rttMonLatestJitterOperMOS},
    );
    $self->set_thresholds(metric => $label,
        warning => "4:",
        critical => "3.5:",
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterOperMOS}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterOperMOS},
        min => 0,
        max => 6,
    );
  
    $label = $self->{name}."_"."jitter_icpif";
    $self->add_info(sprintf "ICPIF value was %.2f",
        $self->{rttMonLatestJitterOperICPIF},
    );
    $self->set_thresholds(metric => $label,
        warning => 20,
        critical => 30,
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterOperICPIF}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterOperICPIF},
        min => 0,
        max => 60,
    );
  
    $label = $self->{name}."_"."pos_jitter_sd";
    $self->add_info(sprintf "Avg. positive jitter from source to dest was %.2f",
        $self->{rttMonLatestJitterOperSumOfPositivesSD},
    );
    $self->set_thresholds(metric => $label,
        warning => "",
        critical => 50,
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterOperSumOfPositivesSD}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterOperSumOfPositivesSD},
    );
  
    $label = $self->{name}."_"."neg_jitter_sd";
    $self->add_info(sprintf "Avg. negative jitter from source to dest was %.2f",
        $self->{rttMonLatestJitterOperSumOfNegativesSD},
    );
    $self->set_thresholds(metric => $label,
        warning => "",
        critical => "-50:",
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterOperSumOfNegativesSD}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterOperSumOfNegativesSD},
    );
  
    $label = $self->{name}."_"."pos_jitter_ds";
    $self->add_info(sprintf "Avg. positive jitter from source to dest was %.2f",
        $self->{rttMonLatestJitterOperSumOfPositivesDS},
    );
    $self->set_thresholds(metric => $label,
        warning => "",
        critical => 50,
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterOperSumOfPositivesDS}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterOperSumOfPositivesDS},
    );
  
    $label = $self->{name}."_"."neg_jitter_ds";
    $self->add_info(sprintf "Avg. negative jitter from source to dest was %.2f",
        $self->{rttMonLatestJitterOperSumOfNegativesDS},
    );
    $self->set_thresholds(metric => $label,
        warning => "",
        critical => "-50:",
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterOperSumOfNegativesDS}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterOperSumOfNegativesDS},
    );
  
    $label = $self->{name}."_"."jitter_packet_loss_count";
    $self->add_info(sprintf "Avg. jitter packet loss was %d",
        $self->{rttMonLatestJitterOperPacketLossCount},
    );
    $self->set_thresholds(metric => $label,
        warning => 0,
        critical => 0,
    );
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{rttMonLatestJitterOperPacketLossCount}));
    $self->add_perfdata(label => $label,
        value => $self->{rttMonLatestJitterOperPacketLossCount},
    );
  }
}

