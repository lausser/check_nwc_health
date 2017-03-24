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
      @rmontable_columns = grep {
        my $ec = $_;
        grep {
          $ec eq $_;
        } @reports;
      } @rmontable_columns;
    }
    if (@ethertable_columns) {
      # will ich ueberhaupt was von dem zeug?
      push(@ethertable_columns, qw(
          dot3StatsIndex
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
    $self->update_interface_cache(0);
    my $only_admin_up =
        $self->opts->name && $self->opts->name eq '_adminup_' ? 1 : 0;
    my $only_oper_up =
        $self->opts->name && $self->opts->name eq '_operup_' ? 1 : 0;
    if ($only_admin_up || $only_oper_up) {
      $self->override_opt('name', undef);
    }
    my @indices = $self->get_interface_indices();
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
        if ($only_admin_up || $only_oper_up) {
          push(@indices, [$_->{ifIndex}]);
        }
      }
      if ($self->mode =~ /device::interfaces::etherstats/) {
        @indices = @save_indices;
        my @etherpatterns = map {
            '('.$_.')';
        } map {
            $_->[0];
        } @indices;
        my @rmonpatterns = map {
            '('.$_.')';
        } map {
            $_->[0];
        } @indices;
        if (@ethertable_columns) {
          if ($self->opts->name) {
            $self->override_opt('drecksptkdb', '^('.join('|', @etherpatterns).')$');
            $self->override_opt('name', '^('.join('|', @etherpatterns).')$');
            $self->override_opt('regexp', 1);
          }
          # key=dot3StatsIndex-//-index, value=index
          $self->update_entry_cache(0, 'ETHERLIKE-MIB', 'dot3StatsTable', 'dot3StatsIndex');
          #
          # ohne name -> get_table
          # mit name -> lauter einzelne indizierte walkportionen
          foreach my $etherstat ($self->get_snmp_table_objects_with_cache(
              'ETHERLIKE-MIB', 'dot3StatsTable', 'dot3StatsIndex', \@ethertable_columns)) {
            foreach my $interface (@{$self->{interfaces}}) {
              if ($interface->{ifIndex} == $etherstat->{dot3StatsIndex}) {
                foreach my $key (grep /^dot3/, keys %{$etherstat}) {
                  $interface->{$key} = $etherstat->{$key};
                }
                push(@{$interface->{columns}}, @ethertable_columns);
                last;
              }
            }
          }
          @{$self->{interfaces}} = grep {
              exists $_->{dot3StatsIndex};
          } @{$self->{interfaces}};
        }
        if (@rmontable_columns) {
          if ($self->opts->name) {
            $self->override_opt('drecksptkdb', '^('.join('|', @rmonpatterns).')$');
            $self->override_opt('name', '^('.join('|', @rmonpatterns).')$');
            $self->override_opt('regexp', 1);
          }
          # key=etherStatsDataSource-//-index, value=index
          $self->update_entry_cache(0, 'OLD-CISCO-INTERFACES-MIB', 'lifTable', 'flat_indices');
          # Value von etherStatsDataSource entspricht ifIndex 1.3.6.1.2.1.2.2.1.1.idx
          foreach my $etherstat ($self->get_snmp_table_objects_with_cache(
              'OLD-CISCO-INTERFACES-MIB', 'lifTable', 'flat_indices', \@rmontable_columns)) {
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


