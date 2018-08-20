package Classes::IFMIB::Component::StackSubsystem;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);
use strict;


sub init {
  my ($self) = @_;
  my @iftable_columns = qw(ifDescr ifAlias ifOperStatus ifAdminStatus);
  $self->update_interface_cache(0);
  my @higher_indices = $self->get_interface_indices();
  if (! $self->opts->name) {
    # get_table erzwingen
    @higher_indices = ();
  } elsif (scalar(@higher_indices)) {
    @higher_indices = map { $_->[0] } @higher_indices;
  } else {
    @higher_indices = ();
  }
  $self->get_snmp_tables("IFMIB", [
      ['stacks', 'ifStackTable', 'Classes::IFMIB::Component::StackSubsystem::Relationship'],
  ]);
  my @lower_indices = ();
  foreach my $rel (@{$self->{stacks}}) {
    if ($self->opts->name) {
      if (grep { $rel->{ifStackHigherLayer} == $_ } @higher_indices) {
        push(@lower_indices, $rel->{ifStackLowerLayer});
      }
    } else {
      if ($rel->{ifStackLowerLayer} && $rel->{ifStackHigherLayer}) {
        push(@higher_indices, $rel->{ifStackHigherLayer});
        push(@lower_indices, $rel->{ifStackLowerLayer});
      }
    }
  }
  @higher_indices = keys %{{map {($_ => 1)} @higher_indices}};
  @lower_indices = grep { $_ != 0 } keys %{{map {($_ => 1)} @lower_indices}};
  my @indices = map { [$_] } keys %{{map {($_ => 1)} (@higher_indices, @lower_indices)}};
  my $higher_interfaces = {};
  my $lower_interfaces = {};
  $self->{interfaces} = [];
  if (! $self->opts->name || scalar(@higher_indices) > 0) {
    my $indices = {};
    foreach ($self->get_snmp_table_objects(
        'IFMIB', 'ifTable+ifXTable', \@indices, \@iftable_columns)) {
      my $interface = Classes::IFMIB::Component::InterfaceSubsystem::Interface->new(%{$_});
      $higher_interfaces->{$interface->{ifIndex}} = $interface if grep { $interface->{ifIndex} == $_ } @higher_indices;
      $lower_interfaces->{$interface->{ifIndex}} = $interface if grep { $interface->{ifIndex} == $_ } @lower_indices;
      push(@{$self->{interfaces}}, $interface);
    }
  }
  $self->{higher_interfaces} = $higher_interfaces;
  $self->{lower_interfaces} = $lower_interfaces;
  @{$self->{stacks}} = grep {
    my $rel = $_;
    grep { $rel->{ifStackHigherLayer} eq $_; } @higher_indices;
  } @{$self->{stacks}};
  $self->arista_schlamperei();
  $self->link_stack_to_interfaces();
}

sub link_stack_to_interfaces {
  my ($self) = @_;
  foreach my $rel (@{$self->{stacks}}) {
    if ($rel->{ifStackHigherLayer} == 0) {
      $rel->{ifStackHigherLayerInterface} = "-";
    } elsif (exists $self->{higher_interfaces}->{$rel->{ifStackHigherLayer}}) {
      $rel->{ifStackHigherLayerInterface} = $self->{higher_interfaces}->{$rel->{ifStackHigherLayer}}->{ifDescr};
    } elsif (exists $self->{lower_interfaces}->{$rel->{ifStackHigherLayer}}) {
      $rel->{ifStackHigherLayerInterface} = $self->{lower_interfaces}->{$rel->{ifStackHigherLayer}}->{ifDescr};
    } else {
      $rel->{ifStackHigherLayerInterface} = "?";
    }
    if ($rel->{ifStackLowerLayer} == 0) {
      $rel->{ifStackLowerLayerInterface} = "-";
    } elsif (exists $self->{higher_interfaces}->{$rel->{ifStackLowerLayer}}) {
      $rel->{ifStackLowerLayerInterface} = $self->{higher_interfaces}->{$rel->{ifStackLowerLayer}}->{ifDescr};
    } elsif (exists $self->{lower_interfaces}->{$rel->{ifStackLowerLayer}}) {
      $rel->{ifStackLowerLayerInterface} = $self->{lower_interfaces}->{$rel->{ifStackLowerLayer}}->{ifDescr};
    } else {
      $rel->{ifStackLowerLayerInterface} = "?";
    }
  }
}

sub arista_schlamperei {
  my ($self) = @_;
  # sowas hier. 
  # IF-MIB::ifStackStatus.0.1000004 = INTEGER: active(1)
  # IF-MIB::ifStackStatus.1000004.0 = INTEGER: active(1)
  # IF-MIB::ifStackStatus.1000004.50 = INTEGER: active(1)
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
  # und noch so eine Besonderheit von Arista.
  # Die IF-MIB::ifStackStatus.1000004.[>0] verschwinden einfach, wenn die lower
  # Interfaces wegbrechen. Die Upper-Lower-Zuordnung ist dann nur noch
  # in der Konsole sichtbar.
}

sub check {
  my ($self) = @_;
  my $higher_interfaces = $self->{higher_interfaces};
  my $lower_interfaces = $self->{lower_interfaces};
  my $lower_needed = {};
  my $lower_counter = {};
  if (! scalar keys %{$higher_interfaces}) {
    $self->add_ok("no portchannels found");
  } elsif (! scalar (@{$self->{stacks}})) {
    $self->add_ok("no portchannels found, ifStackTable is empty or unreadable");
  } else {
    foreach my $rel (@{$self->{stacks}}) {
      next if ! exists $higher_interfaces->{$rel->{ifStackHigherLayer}};
      $lower_counter->{$rel->{ifStackHigherLayer}} = 0
          if ! exists $lower_counter->{$rel->{ifStackHigherLayer}};
      $lower_needed->{$rel->{ifStackHigherLayer}} = 0
          if ! exists $lower_needed->{$rel->{ifStackHigherLayer}};
      if ($rel->{ifStackLowerLayer} == 0 && $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAdminStatus} eq 'down') {
        if ($self->mode =~ /device::interfaces::ifstack::status/) {
          $self->add_ok(sprintf '%s (%s) is admin down',
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
          );
        }
      } elsif ($rel->{ifStackLowerLayer} == 0 && $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifOperStatus} eq 'lowerLayerDown' && defined $self->opts->mitigation()) {
        if ($self->mode =~ /device::interfaces::ifstack::status/) {
          # Port-channel members are supposed to be down, for example
          # in a firewall cluster setup.
          # So this _could_ be a desired state. In order to allow this
          # state, it must be mitigated.
          $self->add_ok(sprintf '%s (%s) has stack status %s but upper interface has lowerLayerDown and no sublayer interfaces', $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
              $rel->{ifStackStatus});
        }
      } elsif ($rel->{ifStackLowerLayer} == 0 && $rel->{ifStackStatus} ne 'notInService') {
        if ($self->mode =~ /device::interfaces::ifstack::status/) {
          if ($rel->{ifStackLowerLayer} == 0 && $rel->{ifStackStatus} ne 'notInService') {
            $self->add_warning(sprintf '%s (%s) has stack status %s but no sub-layer interfaces. Oper status is %s',
                $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
                $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
                $rel->{ifStackStatus},
                $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifOperStatus});
          } else {
            $self->add_warning(sprintf '%s (%s) has stack status %s but no sub-layer interfaces', $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
                $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
                $rel->{ifStackStatus});
          }
        }
      } elsif ($rel->{ifStackStatus} ne 'notInService' &&
          $lower_interfaces->{$rel->{ifStackLowerLayer}}->{ifOperStatus} ne 'up' &&
          $lower_interfaces->{$rel->{ifStackLowerLayer}}->{ifAdminStatus} ne 'down') {
        if ($self->mode =~ /device::interfaces::ifstack::status/) {
          $self->add_critical(sprintf '%s (%s) has a sub-layer interface %s with status %s',
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
              $lower_interfaces->{$rel->{ifStackLowerLayer}}->{ifDescr},
              $lower_interfaces->{$rel->{ifStackLowerLayer}}->{ifOperStatus});
        }
        $lower_needed->{$rel->{ifStackHigherLayer}}++;
      } elsif ($rel->{ifStackStatus} ne 'notInService' &&
          $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifOperStatus} eq 'lowerLayerDown') {
        if ($self->mode =~ /device::interfaces::ifstack::status/) {
          $self->add_critical(sprintf '%s (%s) has status %s',
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifOperStatus});
        }
        $lower_counter->{$rel->{ifStackHigherLayer}}++;
        $lower_needed->{$rel->{ifStackHigherLayer}}++;
      } else {
        $lower_counter->{$rel->{ifStackHigherLayer}}++;
        $lower_needed->{$rel->{ifStackHigherLayer}}++;
      }
    }
    foreach my $interface (@{$self->{interfaces}}) {
      # gibt diese:
      # IF-MIB::ifStackStatus.0.1000201 = INTEGER: active(1)
      # IF-MIB::ifStackStatus.1000201.3 = INTEGER: active(1)
      # und diese
      # IF-MIB::ifStackStatus.0.1000501 = INTEGER: active(1)
      # der braeuchte eigentlich ein
      # IF-MIB::ifStackStatus.1000501.0 = INTEGER: active(1)
      # hat er aber nicht. deshalb waere $lower_counter/lower_needed
      # uninitialized, wenn nicht wieder mal der Lausser den 
      # Drecksmurkssnmpimplementierungen hinterherraeumen wuerde.
      if (! exists $lower_counter->{$interface->{ifIndex}}) {
        $lower_counter->{$interface->{ifIndex}} = 0;
      }
      if (! exists $lower_needed->{$interface->{ifIndex}}) {
        $lower_needed->{$interface->{ifIndex}} = 0;
      }
      # und gleich nochmal. 
      # IF-MIB::ifStackStatus.0.1000027 = INTEGER: active(1)
      # IF-MIB::ifStackStatus.1000027.0 = INTEGER: active(1)
      # IF-MIB::ifStackStatus.0.1000051 = INTEGER: active(1)
      # IF-MIB::ifStackStatus.1000051.35 = INTEGER: active(1)
      # IF-MIB::ifStackStatus.0.1000052 = INTEGER: active(1)
      # Schammts eich, Cisco. Pfui Deifl!
    }
    foreach my $index (keys %{$higher_interfaces}) {
      if ($self->mode =~ /device::interfaces::ifstack::status/) {
        $self->add_ok(sprintf 'interface %s has %d sub-layers',
            $higher_interfaces->{$index}->{ifDescr},
            $lower_counter->{$index});
      } elsif ($self->mode =~ /device::interfaces::ifstack::availability/) {
        my $availability = $lower_needed->{$index} ?
            (100 * $lower_counter->{$index} / $lower_needed->{$index}) : 0;
        my $cavailability = $availability == int($availability) ?
            $availability + 1: int($availability + 1.0);
        $self->add_info(sprintf '%s has %d of %d running sub-layer interfaces, availability is %.2f%%',
            $higher_interfaces->{$index}->{ifDescr},
            $lower_counter->{$index},
            $lower_needed->{$index},
            $availability);
        $self->set_thresholds(
            metric => 'aggr_'.$higher_interfaces->{$index}->{ifDescr}.'_availability',
            warning => '100:',
            critical => $cavailability.':'
        );
        $self->add_message($self->check_thresholds(
            metric => 'aggr_'.$higher_interfaces->{$index}->{ifDescr}.'_availability',
            value => $availability,
        ));
        $self->add_perfdata(
            label => 'aggr_'.$higher_interfaces->{$index}->{ifDescr}.'_availability',
            value => $availability,
            uom => '%',
        );
      }
    }
    $self->reduce_messages_short(sprintf '%d portchannel%s working fine',
        scalar(keys %{$higher_interfaces}),
        scalar(keys %{$higher_interfaces}) ? 's' : '',
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

