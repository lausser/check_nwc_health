package Classes::F5::F5BIGIP::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my $self = shift;
  if ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_objects('F5-BIGIP-SYSTEM-MIB', (qw(sysAttrFailoverIsRedundant sysCmFailoverStatusId sysCmFailoverStatusColor sysCmFailoverStatusSummary)));
    $self->get_snmp_tables("F5-BIGIP-SYSTEM-MIB", [
      ['failoverstatusdetails', 'sysCmFailoverStatusDetailsTable', 'Classes::F5::F5BIGIP::Component::HaSubsystem::FailoverStatusDetails'],
    ]);
    $self->get_snmp_tables("F5-BIGIP-SYSTEM-MIB", [
      ['trafficgroupstatus', 'sysCmTrafficGroupStatusTable', 'Classes::F5::F5BIGIP::Component::HaSubsystem::TrafficGroupStatus'],
    ]);
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active'); # active/standby/standalone
    }
  }
}

sub check {
  my $self = shift;

  # The color of the failover status on the system.
  #   0 green - the system is functioning correctly;
  #   1 yellow - the system may be functioning suboptimally;
  #   2 red - the system requires attention to function correctly;
  #   3 blue - the system's status is unknown or incomplete;
  #   4 gray - the system is intentionally not functioning (offline);
  #   5 black - the system is not connected to any peers."

  my $msg = sprintf("ha %sstarted, role is %s (%s)",
      $self->{sysAttrFailoverIsRedundant} eq 'true' ? '' : 'not ',
      $self->{sysCmFailoverStatusId},
      $self->{sysCmFailoverStatusColor});

  # Note: verification needed that sysAttrFailoverIsRedundant is reliable to detect
  #       clustering enabled state
  if ( $self->{sysAttrFailoverIsRedundant} ) {
    if ( $self->opts->role() eq 'standalone' ) {
      $self->add_warning(sprintf "Unexpected failover status for standalone node: %s (%s)",
        $self->{sysCmFailoverStatusId},
        $self->{sysCmFailoverStatusColor},
      );
    } else {
      # failover is enabled, check node has proper state according to role
      if ( $self->{sysCmFailoverStatusId} eq $self->opts->role() ) {
        $self->add_ok($msg);
      } else {
        $self->add_critical_mitigation($msg);
        $self->add_message(defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
          sprintf "%s, expected role %s", $self->{sysCmFailoverStatusSummary}, $self->opts->role());
      }
    }
  } else {
    if ( $self->opts->role() eq 'standalone' ) {
      $self->add_ok($msg);
    } else {
      $self->add_critical($msg);
    }
  }

  if ( scalar(@{$self->{failoverstatusdetails}}) > 0 ) {
    $self->add_info("Failover Status Details:");
    foreach (@{$self->{failoverstatusdetails}}) {
      $_->check();
    }
  }

  if ( scalar(@{$self->{trafficgroupstatus}}) > 0 ) {
    $self->add_info("Traffic Groups:");
    foreach (@{$self->{trafficgroupstatus}}) {
      $_->check();
    }
  }
}

package Classes::F5::F5BIGIP::Component::HaSubsystem::FailoverStatusDetails;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info($self->{sysCmFailoverStatusDetailsDetails});
}

package Classes::F5::F5BIGIP::Component::HaSubsystem::TrafficGroupStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  # TODO: should probably add some real checking...
  $self->add_info(sprintf "%s: %s -> %s",
    $self->{sysCmTrafficGroupStatusTrafficGroup},
    $self->{sysCmTrafficGroupStatusDeviceName},
    $self->{sysCmTrafficGroupStatusFailoverStatus}
  );
}

