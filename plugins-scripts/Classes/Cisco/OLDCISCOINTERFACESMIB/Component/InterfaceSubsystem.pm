package Classes::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->{interfaces} = [];
  $self->{etherstats} = [];
  #$self->session_translate(['-octetstring' => 1]);
  my @iftable_columns = qw(ifIndex ifDescr ifAlias ifName);
  my @ethertable_columns = qw();
  my @ethertablehc_columns = qw();
  my @rmontable_columns = qw();
  if ($self->mode =~ /device::interfaces::etherstats/) {
    push(@iftable_columns, qw(
        ifOperStatus ifAdminStatus
        ifInMulticastPkts ifOutMulticastPkts
        ifInBroadcastPkts ifOutBroadcastPkts
        ifInUcastPkts ifOutUcastPkts
        ifHCInMulticastPkts ifHCOutMulticastPkts
        ifHCInBroadcastPkts ifHCOutBroadcastPkts
        ifHCInUcastPkts ifHCOutUcastPkts
    ));
    push(@ethertable_columns, qw(
        dot3StatsAlignmentErrors dot3StatsFCSErrors
        dot3StatsSingleCollisionFrames dot3StatsMultipleCollisionFrames
        dot3StatsSQETestErrors dot3StatsDeferredTransmissions
        dot3StatsLateCollisions dot3StatsExcessiveCollisions
        dot3StatsInternalMacTransmitErrors dot3StatsCarrierSenseErrors
        dot3StatsFrameTooLongs dot3StatsInternalMacReceiveErrors
    ));
    push(@ethertablehc_columns, qw(
        dot3HCStatsFCSErrors
    ));
    push(@rmontable_columns, qw(
        locIfInCRC
    ));
    if ($self->opts->report !~ /^(long|short|html)$/) {
      my @reports = split(',', $self->opts->report);
      @ethertable_columns = grep {
        my $ec = $_;
        grep {
          $ec eq $_;
        } @reports;
      } @ethertable_columns;
      @ethertablehc_columns = grep {
        my $ec = $_;
        grep {
          $ec eq $_;
        } @reports;
      } @ethertablehc_columns;
      @rmontable_columns = grep {
        my $ec = $_;
        grep {
          $ec eq $_;
        } @reports;
      } @rmontable_columns;
    }
    if (grep /dot3HCStatsFCSErrors/, @ethertablehc_columns) {
      # wenn ifSpeed == 4294967295, dann 10GBit, dann dot3HCStatsFCSErrors
      push(@iftable_columns, qw(
          ifSpeed
      ));
    }
    if (@rmontable_columns) {
      push(@rmontable_columns, qw(
        locIfDescr
        locIfHardType
      ));
    }
  } else {
    $self->SUPER::init();
  }
  if ($self->mode =~ /device::interfaces::etherstats/) {
    my $if_has_changed = $self->update_interface_cache(0);
    my $only_admin_up =
        $self->opts->name && $self->opts->name eq '_adminup_' ? 1 : 0;
    my $only_oper_up =
        $self->opts->name && $self->opts->name eq '_operup_' ? 1 : 0;
    if ($only_admin_up || $only_oper_up) {
      $self->override_opt('name', undef);
      $self->override_opt('drecksptkdb', undef);
    }
    my @indices = $self->get_interface_indices();
    my @all_indices = @indices;
    my @selected_indices = ();
    if (! $self->opts->name && ! $self->opts->name3) {
      # get_table erzwingen
      @indices = ();
      $self->bulk_is_baeh(10);
    }
    if (!$self->opts->name || scalar(@indices) > 0) {
      my @save_indices = @indices; # die werden in get_snmp_table_objects geshiftet
      foreach ($self->get_snmp_table_objects(
          'IFMIB', 'ifTable+ifXTable', \@indices, \@iftable_columns)) {
        next if $only_admin_up && $_->{ifAdminStatus} ne 'up';
        next if $only_oper_up && $_->{ifOperStatus} ne 'up';
        my $interface = Classes::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem::Interface->new(%{$_});
        $interface->{columns} = [@iftable_columns];
        push(@{$self->{interfaces}}, $interface);
      }
      if ($self->mode =~ /device::interfaces::etherstats/) {
        @indices = @save_indices;
        my @etherindices = ();
        my @etherhcindices = ();
        my @lifindices = ();
        foreach my $interface (@{$self->{interfaces}}) {
          push(@selected_indices, [$interface->{ifIndex}]);
          if (@ethertablehc_columns && $interface->{ifSpeed} == 4294967295) {
            push(@etherhcindices, [$interface->{ifIndex}]);
          }
          push(@etherindices, [$interface->{ifIndex}]);
          push(@lifindices, [$interface->{ifIndex}]);
        }
        $self->debug(
            sprintf 'all_interfaces %d, selected %d, ether %d, etherhc %d',
                scalar(@all_indices), scalar(@selected_indices),
                scalar(@etherindices), scalar(@etherhcindices));
        if ($only_admin_up || $only_oper_up) {
          if (scalar(@etherindices) > scalar(@all_indices) * 0.70) {
            $self->bulk_is_baeh(20);
            @etherindices = ();
          }
          if (scalar(@etherhcindices) > scalar(@all_indices) * 0.70) {
            $self->bulk_is_baeh(20);
            @etherhcindices = ();
          }
          if (scalar(@lifindices) > scalar(@all_indices) * 0.70) {
            $self->bulk_is_baeh(20);
            @lifindices = ();
          }
        } elsif (! @indices) {
            $self->bulk_is_baeh(20);
          @etherindices = ();
          if (scalar(@etherhcindices) > scalar(@all_indices) * 0.70) {
            @etherhcindices = ();
          }
          @lifindices = ();
        }
        if (@ethertable_columns) {
          # es gibt interfaces mit ifSpeed == 4294967295
          # aber nix in dot3HCStatsTable. also dann dot3StatsTable fuer alle
          foreach my $etherstat ($self->get_snmp_table_objects(
              'ETHERLIKE-MIB', 'dot3StatsTable', \@etherindices, \@ethertable_columns)) {
            foreach my $interface (@{$self->{interfaces}}) {
              if ($interface->{ifIndex} == $etherstat->{flat_indices}) {
                foreach my $key (grep /^dot3/, keys %{$etherstat}) {
                  $interface->{$key} = $etherstat->{$key};
                }
                push(@{$interface->{columns}}, @ethertable_columns);
                last;
              }
            }
          }
        }
        if (@ethertablehc_columns && scalar(@etherhcindices)) {
          foreach my $etherstat ($self->get_snmp_table_objects(
              'ETHERLIKE-MIB', 'dot3HCStatsTable', \@etherhcindices, \@ethertablehc_columns)) {
            foreach my $interface (@{$self->{interfaces}}) {
              if ($interface->{ifIndex} == $etherstat->{flat_indices}) {
                foreach my $key (grep /^dot3/, keys %{$etherstat}) {
                  $interface->{$key} = $etherstat->{$key};
                }
                push(@{$interface->{columns}}, @ethertablehc_columns);
                if (grep /^dot3HCStatsFCSErrors/, @{$interface->{columns}}) {
                  @{$interface->{columns}} = grep {
                    $_ if $_ ne 'dot3StatsFCSErrors';
                  } @{$interface->{columns}};
                }
                last;
              }
            }
          }
        }
        if (@rmontable_columns) {
          foreach my $etherstat ($self->get_snmp_table_objects(
              'OLD-CISCO-INTERFACES-MIB', 'lifTable', \@lifindices, \@rmontable_columns)) {
            foreach my $interface (@{$self->{interfaces}}) {
              if ($interface->{ifIndex} eq $etherstat->{flat_indices}) {
                foreach my $key (grep /^locIf/, keys %{$etherstat}) {
                  $interface->{$key} = $etherstat->{$key};
                }
                push(@{$interface->{columns}}, @rmontable_columns);
                last;
              }
            }
          }
          @{$self->{interfaces}} = grep {
              grep /locIf/, keys %{$_};
          } @{$self->{interfaces}};
        }
        foreach my $interface (@{$self->{interfaces}}) {
          delete $interface->{dot3StatsIndex};
          delete $interface->{locIfDescr};
          delete $interface->{locIfHardType};
          @{$interface->{columns}} = grep {
              $_ !~ /^(dot3StatsIndex|locIfDescr|locIfHardType)$/;
          } @{$interface->{columns}};
          $interface->init_etherstats;
        }
      }
    }
  } else {
    $self->SUPER::init();
  }
}


package Classes::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;
use Digest::MD5 qw(md5_hex);


sub finish {
  my ($self) = @_;
  foreach my $key (keys %{$self}) {
    next if $key !~ /^if/;
    $self->{$key} = 0 if ! defined $self->{$key};
  }
  $self->{ifDescr} = unpack("Z*", $self->{ifDescr}); # windows has trailing nulls
  if ($self->opts->name2 && $self->opts->name2 =~ /\(\.\*\?*\)/) {
    if ($self->{ifDescr} =~ $self->opts->name2) {
      $self->{ifDescr} = $1;
    }
  }
  # Manche Stinkstiefel haben ifName, ifHighSpeed und z.b. ifInMulticastPkts,
  # aber keine ifHC*Octets. Gesehen bei Cisco Switch Interface Nul0 o.ae.
  if ($self->{ifName} && defined $self->{ifHCInUcastPkts} &&
      defined $self->{ifHCOutUcastPkts} && $self->{ifHCInUcastPkts} ne "noSuchObject") {
    $self->{ifAlias} ||= $self->{ifName};
    $self->{ifName} = unpack("Z*", $self->{ifName});
    $self->{ifAlias} = unpack("Z*", $self->{ifAlias});
    $self->{ifAlias} =~ s/\|/!/g if $self->{ifAlias};
    bless $self,'Classes::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem::Interface::64bit';
  }
  if (! exists $self->{ifInUcastPkts} && ! exists $self->{ifOutUcastPkts} &&
      $self->mode =~ /device::interfaces::(broadcast|complete|etherstats)/) {
    bless $self, 'Classes::IFMIB::Component::InterfaceSubsystem::Interface::StackSub';
  }
  if ($self->{ifPhysAddress}) {
    $self->{ifPhysAddress} = join(':', unpack('(H2)*', $self->{ifPhysAddress})); 
  }
  $self->init();
}

sub init_etherstats {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::etherstats/) {
    $Monitoring::GLPlugin::mode = "device::interfaces::broadcasts";
    $self->init();
    $Monitoring::GLPlugin::mode = "device::interfaces::etherstats";
    # in the beginning we start 32/64bit-unaware, so columns contain
    # also ifHC-names, but there are no such attributes in the interface object
    @{$self->{columns}} = grep {
      ! /^ifHC(In|Out).*castPkts$/
    } grep {
      ! /^(ifOperStatus|ifAdminStatus|ifIndex|ifDescr|ifAlias|ifName)$/
    } @{$self->{columns}};
    my $ident = $self->{ifDescr}.md5_hex(join('_', @{$self->{columns}}));
    $self->valdiff({name => $ident}, @{$self->{columns}});
    $self->{delta_InPkts} = $self->{delta_ifInUcastPkts} +
        $self->{delta_ifInMulticastPkts} + $self->{delta_ifInBroadcastPkts};
    $self->{delta_OutPkts} = $self->{delta_ifOutUcastPkts} +
        $self->{delta_ifOutMulticastPkts} + $self->{delta_ifOutBroadcastPkts};
    for my $stat (grep { /^(dot3|locIf)/ } @{$self->{columns}}) {
      next if ! defined $self->{'delta_'.$stat};
      $self->{$stat.'Percent'} = $self->{delta_InPkts} + $self->{delta_OutPkts} ?
          100 * $self->{'delta_'.$stat} /
          ($self->{delta_InPkts} + $self->{delta_OutPkts}) : 0;
    }
  }
  return $self;
}

sub check {
  my ($self) = @_;
  my $full_descr = sprintf "%s%s",
      $self->{ifDescr},
      $self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr} ?
          " (alias ".$self->{ifAlias}.")" : "";
  if ($self->mode =~ /device::interfaces::etherstats/) {
    for my $stat (grep { /^(dot3|locIf)/ } @{$self->{columns}}) {
      next if ! defined $self->{$stat.'Percent'};
      my $label = $stat.'Percent';
      $label =~ s/^(dot3Stats|locIf)//g;
      $label =~ s/(?:\b|(?<=([a-z])))([A-Z][a-z]+)/(defined($1) ? "_" : "") . lc($2)/eg;
      $label = $self->{ifDescr}.'_'.$label;
      $self->add_info(sprintf 'interface %s %s is %.2f%%',
          $full_descr, $stat.'Percent', $self->{$stat.'Percent'});
      $self->set_thresholds(
          metric => $label,
          warning => 1,
          critical => 10
      );
      $self->add_message(
          $self->check_thresholds(metric => $label, value => $self->{$stat.'Percent'}));
      $self->add_perfdata(
          label => $label,
          value => $self->{$stat.'Percent'},
          uom => '%',
      );
    }
  } else {
    $self->SUPER::check();
  }
}


package Classes::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem::Interface::64bit;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface::64bit Classes::Cisco::OLDCISCOINTERFACESMIB::Component::InterfaceSubsystem::Interface);
use strict;
use Digest::MD5 qw(md5_hex);

sub init_etherstats {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::etherstats/) {
    $Monitoring::GLPlugin::mode = "device::interfaces::broadcasts";
    $self->init();
    $Monitoring::GLPlugin::mode = "device::interfaces::etherstats";
    # 32bit-cast ausputzen. es gibt welche, die haben nur 64bit
    @{$self->{columns}} = grep {
      ! /^if(In|Out).*castPkts$/
    } grep {
      ! /^(ifOperStatus|ifAdminStatus|ifIndex|ifDescr|ifAlias|ifName)$/
    } @{$self->{columns}};
    my $ident = $self->{ifDescr}.md5_hex(join('_', @{$self->{columns}}));
    $self->valdiff({name => $ident}, @{$self->{columns}});
    $self->{delta_InPkts} = $self->{delta_ifHCInUcastPkts} +
        $self->{delta_ifHCInMulticastPkts} + $self->{delta_ifHCInBroadcastPkts};
    $self->{delta_OutPkts} = $self->{delta_ifHCOutUcastPkts} +
        $self->{delta_ifHCOutMulticastPkts} + $self->{delta_ifHCOutBroadcastPkts};
    for my $stat (grep { /^(dot3|locIf)/ } @{$self->{columns}}) {
      next if ! defined $self->{'delta_'.$stat};
      $self->{$stat.'Percent'} = $self->{delta_InPkts} + $self->{delta_OutPkts} ?
          100 * $self->{'delta_'.$stat} /
          ($self->{delta_InPkts} + $self->{delta_OutPkts}) : 0;
    }
  }
  return $self;
}


