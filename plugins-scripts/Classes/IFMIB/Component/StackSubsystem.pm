package Classes::IFMIB::Component::StackSubsystem;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);
use strict;


sub init {
  my ($self) = @_;
  my @iftable_columns = qw(ifDescr ifAlias ifOperStatus ifAdminStatus);
  $self->update_interface_cache(0);
  my @selected_indices = $self->get_interface_indices();
  if (! $self->opts->name) {
    # get_table erzwingen
    @selected_indices = ();
  } elsif (scalar(@selected_indices)) {
    @selected_indices = map { $_->[0] } @selected_indices;
  } else {
    # none of the desired interfaces was found. we exit here, otherwise we
    # might find crap resulting in "uninitialized value...." (which happened)
    @selected_indices = ();
    return;
  }
  $self->get_snmp_tables("IFMIB", [
      ['stacks', 'ifStackTable', 'Classes::IFMIB::Component::StackSubsystem::Relationship'],
  ]);
  my @higher_indices = ();
  my @lower_indices = ();
  foreach my $rel (@{$self->{stacks}}) {
    if (@selected_indices) {
      if (defined $rel->{ifStackLowerLayer} && grep { $rel->{ifStackHigherLayer} == $_ } @selected_indices) {
        #push(@higher_indices, $rel->{ifStackHigherLayer}) if $rel->{ifStackLowerLayer};
        push(@higher_indices, $rel->{ifStackHigherLayer});
        push(@lower_indices, $rel->{ifStackLowerLayer});
      }
    } else {
      if (defined $rel->{ifStackLowerLayer} && $rel->{ifStackHigherLayer}) {
        push(@higher_indices, $rel->{ifStackHigherLayer}) if $rel->{ifStackLowerLayer};
        push(@lower_indices, $rel->{ifStackLowerLayer});
      }
    }
  }
  @higher_indices = grep { $_ != 0 } keys %{{map {($_ => 1)} @higher_indices}};
  if (! @{$self->{stacks}} && @selected_indices) {
    # those which don't have a ifStackTable at all
    @higher_indices = @selected_indices;
  }
  @lower_indices = grep { $_ != 0 } keys %{{map {($_ => 1)} @lower_indices}};
  my @indices = map { [$_] } keys %{{map {($_ => 1)} (@higher_indices, @lower_indices, @selected_indices)}};
  $self->{interface_hash} = {};
  if (! $self->opts->name || scalar(@higher_indices) > 0) {
    foreach ($self->get_snmp_table_objects(
        'IFMIB', 'ifTable+ifXTable', @selected_indices ? \@indices : [], \@iftable_columns)) {
      my $interface = Classes::IFMIB::Component::InterfaceSubsystem::Interface->new(%{$_});
      $self->{interface_hash}->{$interface->{ifIndex}} = $interface;
      if (@selected_indices && grep { $interface->{ifIndex} == $_ } @selected_indices) {
        $interface->{lower_interfaces} = [];
        $interface->{stack_status} = [];
      } elsif (grep { $interface->{ifIndex} == $_ } @higher_indices) {
        $interface->{lower_interfaces} = [];
        $interface->{stack_status} = [];
      }
    }
  }
  #$self->arista_schlamperei();
  $self->link_stack_to_interfaces(@higher_indices);
}

sub link_stack_to_interfaces {
  my ($self, @higher_indices) = @_;
  $self->{interfaces} = [];
  foreach my $rel (@{$self->{stacks}}) {
    if ($rel->{ifStackHigherLayer} != 0 && grep { $rel->{ifStackHigherLayer} == $_ } @higher_indices) {
      if ($rel->{ifStackLowerLayer} == 0) {
        # sowas hier. 
        # IF-MIB::ifStackStatus.0.1000004 = INTEGER: active(1)
        # IF-MIB::ifStackStatus.1000004.0 = INTEGER: active(1)
        # IF-MIB::ifStackStatus.1000004.50 = INTEGER: active(1)
        # Arista macht sowas gelegentlich. Der mittlere, falsche Eintrag wird einfach ignoriert.
        # und noch so eine Besonderheit von Arista.
        # Die IF-MIB::ifStackStatus.1000004.[>0] verschwinden einfach, wenn die lower
        # Interfaces wegbrechen. Die Upper-Lower-Zuordnung ist dann nur noch
        # in der Konsole sichtbar.
        $self->{interface_hash}->{$rel->{ifStackHigherLayer}}->{ifStackStatus} = $rel->{ifStackStatus};
      } elsif (exists $self->{interface_hash}->{$rel->{ifStackHigherLayer}}) {
        push(@{$self->{interface_hash}->{$rel->{ifStackHigherLayer}}->{lower_interfaces}},
            $self->{interface_hash}->{$rel->{ifStackLowerLayer}});
        push(@{$self->{interface_hash}->{$rel->{ifStackHigherLayer}}->{stack_status}},
            $rel->{ifStackStatus});
      }
    }
  }
  @{$self->{interfaces}} = sort {
        $a->{ifIndex} <=> $b->{ifIndex}
  } values %{$self->{interface_hash}};
}

sub arista_schlamperei {
  my ($self) = @_;
  my @have_lower = map {
    $_->{ifStackHigherLayer}
  } grep {
    exists $self->{higher_interfaces}->{$_->{ifStackHigherLayer}}
  } grep {
    $_->{ifStackLowerLayer} != 0
  } @{$self->{stacks}};
  @{$self->{stacks}} = grep {
      my $ref = $_;
      ! ($ref->{ifStackLowerLayer} == 0 && grep /^$ref->{ifStackHigherLayer}$/, @have_lower)
  } @{$self->{stacks}};
}

sub check {
  my ($self) = @_;
  if (! $self->{interfaces}) {
    # see beginning of init(). For example --name channel --regex
    # finds no interface of this name
    $self->add_unknown('no interfaces');
    return;
  }
  my @selected_interfaces = sort {
      $a->{ifIndex} <=> $b->{ifIndex}
  } grep {
      exists $_->{lower_interfaces}
  } @{$self->{interfaces}};
  if (! scalar (@{$self->{stacks}}) && ! scalar(@selected_interfaces)) {
    $self->add_ok("no portchannels found, ifStackTable is empty or unreadable");
  } elsif (! scalar(@selected_interfaces)) {
    $self->add_ok("no portchannels found");
  } else {
    foreach my $interface (@selected_interfaces) {
      # Liste der Sublayer Interfaces ist ggf. auch leer
      $interface->{lower_interfaces_ok} = [];
      $interface->{lower_interfaces_fail} = [];
      my $index = 0;
      foreach my $lower (@{$interface->{lower_interfaces}}) {
        if ($lower->{ifOperStatus} ne 'up' && $lower->{ifAdminStatus} ne 'down' &&
            $interface->{stack_status}->[$index] ne 'notInService') {
          push(@{$interface->{lower_interfaces_fail}}, $lower);
        } else {
          push(@{$interface->{lower_interfaces_ok}}, $lower);
        }
        $index++;
      }
      if ($self->mode =~ /device::interfaces::ifstack::status/) {
        if (! scalar (@{$interface->{lower_interfaces}})) {
          if ($interface->{ifAdminStatus} eq 'down') {
            $self->add_ok(sprintf '%s (%s) is admin down',
                $interface->{ifDescr},
                $interface->{ifAlias},
            );
          } elsif ($interface->{ifOperStatus} eq 'lowerLayerDown') {
            # Port-channel members are supposed to be down, for example
            # in a firewall cluster setup.
            # So this _could_ be a desired state. In order to allow this
            # state, it must be mitigated.
            $self->add_critical_mitigation(sprintf '%s%s has status lowerLayerDown and no sublayer interfaces',
                $interface->{ifDescr},
                $interface->{ifAlias} ? " (".$interface->{ifAlias}.")" : "",
            );
          } elsif (! $interface->{ifStackStatus} && $interface->{ifOperStatus} ne "up") {
            # there is no ifStackTable, ifOperStatus is the only info
            $self->add_warning(sprintf '%s%s has no stack status and no sub-layer interfaces. Oper status is %s',
                $interface->{ifDescr},
                $interface->{ifAlias} ? " (".$interface->{ifAlias}.")" : "",
                $interface->{ifOperStatus},
            );
          } elsif ($interface->{ifStackStatus} && $interface->{ifStackStatus} ne 'notInService') {
            $self->add_warning(sprintf '%s%s has stack status %s but no sub-layer interfaces. Oper status is %s',
                $interface->{ifDescr},
                $interface->{ifAlias} ? " (".$interface->{ifAlias}.")" : "",
                $interface->{ifStackStatus},
                $interface->{ifOperStatus},
            );
          } else {
            $self->add_ok(sprintf '%s%s oper status is %s',
                $interface->{ifDescr},
                $interface->{ifAlias} ? " (".$interface->{ifAlias}.")" : "",
                $interface->{ifOperStatus},
            );
          }
        } else {
          if (scalar(@{$interface->{lower_interfaces_fail}})) {
            foreach my $lower (@{$interface->{lower_interfaces_fail}}) {
              $self->add_critical(sprintf '%s%s has a sub-layer interface %s with status %s',
                  $interface->{ifDescr},
                  $interface->{ifAlias} ? " (".$interface->{ifAlias}.")" : "",
                  $lower->{ifDescr},
                  $lower->{ifOperStatus},
              );
            }
          } elsif ($interface->{ifOperStatus} eq 'lowerLayerDown') {
            # maybe something like what happens with Arista. Sub-Interface is configured
            # but as soon as it is broken, it disappears fromthe ifStackTable
            $self->add_critical_mitigation(sprintf '%s%s has status lowerLayerDown',
                $interface->{ifDescr},
                $interface->{ifAlias} ? " (".$interface->{ifAlias}.")" : "",
            );
          } else {
            $self->add_ok(sprintf 'interface %s%s has %d sub-layers',
                $interface->{ifDescr},
                $interface->{ifAlias} ? " (".$interface->{ifAlias}.")" : "",
                scalar(@{$interface->{lower_interfaces_ok}})
            );
          }
        }
      } elsif ($self->mode =~ /device::interfaces::ifstack::availability/) {
        my $lower_interfaces_ok = scalar(@{$interface->{lower_interfaces_ok}});
        my $lower_interfaces_all = scalar(@{$interface->{lower_interfaces_fail}}) + $lower_interfaces_ok;
        my $availability = $lower_interfaces_all ?
            (100 * $lower_interfaces_ok / $lower_interfaces_all) : 0;
        my $cavailability = $availability == int($availability) ?
            $availability + 1: int($availability + 1.0);
        $self->add_info(sprintf '%s has %d of %d running sub-layer interfaces, availability is %.2f%%',
            $interface->{ifDescr},
            $lower_interfaces_ok,
            $lower_interfaces_all,
            $availability);
        $self->set_thresholds(
            metric => 'aggr_'.$interface->{ifDescr}.'_availability',
            warning => '100:',
            critical => $cavailability.':'
        );
        $self->add_message($self->check_thresholds(
            metric => 'aggr_'.$interface->{ifDescr}.'_availability',
            value => $availability,
        ));
        $self->add_perfdata(
            label => 'aggr_'.$interface->{ifDescr}.'_availability',
            value => $availability,
            uom => '%',
        );
      }
    }
    my $num_portchannels = scalar(grep {
        exists $_->{lower_interfaces}
    } @{$self->{interfaces}});
    $self->reduce_messages_short(sprintf '%d portchannel%s working fine',
        $num_portchannels,
        $num_portchannels > 1 ? 's' : '',
    );
  }
}

package Classes::IFMIB::Component::StackSubsystem::Relationship;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{ifStackHigherLayer} = $self->{indices}->[0];
  $self->{ifStackLowerLayer} = $self->{indices}->[1];
}

