package CheckNwcHealth::Arista::ARISTAIFMIB::Component::InterfaceSubsystem;
our @ISA = qw(CheckNwcHealth::IFMIB::Component::InterfaceSubsystem);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::interfacex::errdisable/) {
    $self->get_snmp_tables('ARISTA-IF-MIB', [
        ['status', 'aristaIfTable', 'CheckNwcHealth::Arista::ARISTAIFMIB::Component::InterfaceSubsystem::Status', sub { my $o = shift; exists $_->{aristaIfErrDisabledReason} && $_->{aristaIfErrDisabledReason}; }, ['aristaIfErrDisabledReason']],
    ]); 
    my @disabled_indices = map {
      $_->{indices}->[0];
    } grep {
      exists $_->{aristaIfErrDisabledReason} && $_->{aristaIfErrDisabledReason};
    } @{$self->{status}};

    if (! @{$self->{status}}) {
      return;
    }
    my @iftable_columns = qw(ifIndex ifDescr ifAlias ifName);
    push(@iftable_columns, qw(
       ifOperStatus ifAdminStatus
    ));
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
    # we were filtering by name* or not filtering at all, so we have
    # all the indexes we want
    my @filtered_disabled_indices = ();
    foreach my $index (@indices) {
      foreach my $dindex (@disabled_indices) {
        if ($dindex == $index->[0]) {
          push(@filtered_disabled_indices, [$dindex]) if $dindex == $index->[0];
        }
      }
    }
    # an sich sind wir hier fertig, denn die ifDescr sind in
    # $self->{interface_cache}->{$index}->{ifDescr};
    # und weitere snmp-gets sind ueberfluessig (wenn man auf ifAlias verzichtet).
    # aber da voraussichtlich nur ganz wenige interfaces gefunden werden,
    # welche disabled sind, kann man sich die extra abfrage schon goennen.
    # und frueher oder spaeter kommt eh wieder das geplaerr nach ifalias.
    @indices = @filtered_disabled_indices;
    if (!$self->opts->name || scalar(@indices) > 0) {
      my @save_indices = @indices; # die werden in get_snmp_table_objects geshiftet
      foreach ($self->get_snmp_table_objects(
          'IFMIB', 'ifTable+ifXTable', \@indices, \@iftable_columns)) {
        next if $only_admin_up && $_->{ifAdminStatus} ne 'up';
        next if $only_oper_up && $_->{ifOperStatus} ne 'up';
        my $interface = CheckNwcHealth::Arista::ARISTAIFMIB::Component::InterfaceSubsystem::Interface->new(%{$_});
        foreach my $status (@{$self->{status}}) {
          if ($status->{disabledIfIndex} == $interface->{ifIndex}) {
            push(@{$interface->{disablestatus}}, $status);
          }
        }
        push(@{$self->{interfaces}}, $interface);
      }
    }
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::interfacex::errdisable/) {
    if (! @{$self->{status}}) {
      $self->add_ok("no disabled interfaces on this device");
    } else {
      foreach (@{$self->{interfaces}}) {
        $_->check();
      }
    }
  }
}

package CheckNwcHealth::Arista::ARISTAIFMIB::Component::InterfaceSubsystem::Status;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{disabledIfIndex} = $self->{indices}->[0];
}

package CheckNwcHealth::Arista::ARISTAIFMIB::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{disablestatus} = [];
}

sub check {
  my ($self) = @_;
  my $full_descr = sprintf "%s%s",
      $self->{ifDescr},
      $self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr} ?
          " (alias ".$self->{ifAlias}.")" : "";
  if ($self->{disablestatus}) {
    foreach my $status (@{$self->{disablestatus}}) {
      $self->add_critical(sprintf("%s is disabled, reason: %s",
          $full_descr,
          $status->{aristaIfErrDisabledReason}));
    }
  } else {
    $self->add_ok(sprintf("%s is not disabled", $full_descr));
  }
}


