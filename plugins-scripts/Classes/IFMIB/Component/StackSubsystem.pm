package Classes::IFMIB::Component::StackSubsystem;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);
use strict;


sub init {
  my ($self) = @_;
  $self->update_interface_cache(0);
  my @higher_indices = $self->get_interface_indices();
  if (! $self->opts->name) {
    # get_table erzwingen
    @higher_indices = ();
  }
  $self->get_snmp_tables("IFMIB", [
      ['stacks', 'ifStackTable', 'MyPortchannel::ECSubSys::Relationship'],
  ]);
  my @lower_indices = ();
  foreach my $rel (@{$self->{stacks}}) {
    if ($self->opts->name) {
      if (grep { $rel->{ifStackHigherLayer} == $_ } map { $_->[0]; } @higher_indices) {
        push(@lower_indices, [$rel->{ifStackLowerLayer}]);
      }
    } else {
      if ($rel->{ifStackLowerLayer} && $rel->{ifStackHigherLayer}) {
        push(@higher_indices, [$rel->{ifStackHigherLayer}]);
        push(@lower_indices, [$rel->{ifStackLowerLayer}]);
      }
    }
  }
  @higher_indices = map { [$_] } keys %{{map {($_->[0] => 1)} @higher_indices}};
  @lower_indices = grep { $_->[0] != 0 } map { [$_] } keys %{{map {($_->[0] => 1)} @lower_indices}};
  my @indices = map { [$_] } keys %{{map {($_->[0] => 1)} (@higher_indices, @lower_indices)}};
  my $higher_interfaces = {};
  my $lower_interfaces = {};
  $self->{interfaces} = [];
  if (! $self->opts->name || scalar(@higher_indices) > 0) {
    my $indices = {};
    foreach ($self->get_snmp_table_objects(
        'IFMIB', 'ifTable+ifXTable', \@indices)) {
      my $interface = Classes::IFMIB::Component::InterfaceSubsystem::Interface->new(%{$_});
      $higher_interfaces->{$interface->{ifIndex}} = $interface if grep { $interface->{ifIndex} == $_->[0] } @higher_indices;
      $lower_interfaces->{$interface->{ifIndex}} = $interface if grep { $interface->{ifIndex} == $_->[0] } @lower_indices;
      push(@{$self->{interfaces}}, $interface);
    }
  }
  $self->{higher_interfaces} = $higher_interfaces;
  $self->{lower_interfaces} = $lower_interfaces;
}

sub check {
  my ($self) = @_;
  my $higher_interfaces = $self->{higher_interfaces};
  my $lower_interfaces = $self->{lower_interfaces};
  my $lower_needed = {};
  my $lower_counter = {};
  if (! scalar keys %{$higher_interfaces}) {
    $self->add_ok("no portchannels found");
  } else {
    foreach my $rel (@{$self->{stacks}}) {
      next if ! exists $higher_interfaces->{$rel->{ifStackHigherLayer}};
      if ($rel->{ifStackLowerLayer} == 0 && $rel->{ifStackStatus} ne 'notInService') {
        if ($self->mode =~ /device::interfaces::ifstack::status/) {
          $self->add_warning(sprintf '%s (%s) has stack status %s but no sub-layer interfaces', $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
              $rel->{ifStackStatus});
            $lower_counter->{$rel->{ifStackHigherLayer}} = 0;
        } elsif ($self->mode =~ /device::interfaces::ifstack::availability/) {
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
        } elsif ($self->mode =~ /device::interfaces::ifstack::availability/) {
          $lower_needed->{$rel->{ifStackHigherLayer}}++;
        }
        $lower_counter->{$rel->{ifStackHigherLayer}}++;
      } elsif ($rel->{ifStackStatus} ne 'notInService' &&
          $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifOperStatus} eq 'lowerLayerDown') {
        if ($self->mode =~ /device::interfaces::ifstack::status/) {
          $self->add_critical(sprintf '%s (%s) has status %s',
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifDescr},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifAlias},
              $higher_interfaces->{$rel->{ifStackHigherLayer}}->{ifOperStatus});
        } elsif ($self->mode =~ /device::interfaces::ifstack::availability/) {
          $lower_needed->{$rel->{ifStackHigherLayer}}++;
        }
        $lower_counter->{$rel->{ifStackHigherLayer}}++;
      } else {
        $lower_counter->{$rel->{ifStackHigherLayer}}++;
        $lower_needed->{$rel->{ifStackHigherLayer}}++;
      }
    }
    foreach my $index (keys %{$higher_interfaces}) {
      if ($self->mode =~ /device::interfaces::ifstack::status/) {
        $self->add_ok(sprintf 'interface %s has %d sub-layers',
            $higher_interfaces->{$index}->{ifDescr},
            $lower_counter->{$index});
      } elsif ($self->mode =~ /device::interfaces::ifstack::availability/) {
        $self->set_thresholds(
            metric => $higher_interfaces->{$index}->{ifDescr}.'_availability');


        my $cavailability = $self->{num_if} ? (100 * 1 / $self->{num_if}) : 0;
    $cavailability = $cavailability == int($cavailability) ? $cavailability + 1: int($cavailability + 1.0);
    $self->set_thresholds(
        metric => 'aggr_'.$self->{name}.'_availability',
        warning => '100:',
        critical => $cavailability.':'
    );
    $self->add_message($self->check_thresholds(
        metric => 'aggr_'.$self->{name}.'_availability',
        value => $self->{availability}
    ));
    $self->add_perfdata(
        label => 'aggr_'.$self->{name}.'_availability',
        value => $self->{availability},
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

package MyPortchannel::ECSubSys::Relationship;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{ifStackHigherLayer} = $self->{indices}->[0];
  $self->{ifStackLowerLayer} = $self->{indices}->[1];
}

