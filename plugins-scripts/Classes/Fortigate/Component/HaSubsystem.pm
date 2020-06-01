package Classes::Fortigate::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('FORTINET-CORE-MIB', (qw(
      fnSysSerial
  )));
  $self->get_snmp_objects('FORTINET-FORTIGATE-MIB', (qw(
      fgHaStatsSyncStatus fgHaSystemMode fgHaOverride fgHaAutoSync
      fgHaGroupName fgFcSwSerial fgFcSwName
  )));
  $self->get_snmp_tables('FORTINET-FORTIGATE-MIB', [
      ['fgHaStatsTable', 'fgHaStatsTable', 'Classes::Fortigate::Component::HaSubsystem::SyncStatus'],
      ['fgVdTable', 'fgVdTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  if (! $self->opts->role()) {
    $self->opts->override_opt('role', 'master');
    # fgHaSystemMode: activePassive, activeActive or standalone
    # https://docs.fortinet.com/document/fortigate/6.0.6/handbook/943352/fgcp-ha-glossary
    # Primary unit
    # Also called the primary cluster unit, this cluster unit controls how the cluster operates.
    # The FortiGate firmware uses the term master to refer to the primary unit.
    # Standby State
    # A subordinate unit in an active-passive HA cluster operates in the standby state
    # Subordinate unit
    # Also called the subordinate cluster unit, each cluster contains one or more cluster units that are not functioning as the primary unit.
    # The FortiGate firmware uses the terms slave and subsidiary unit to refer to a subordinate unit.
  }
  foreach (@{$self->{fgHaStatsTable}}) {
    $_->{fnSysSerial} = $self->{fnSysSerial};
    $_->{fgHaSystemMode} = $self->{fgHaSystemMode};
  }
}

# Specify threshold values, so that you understand when the number of units
# decreases, for example we have only 2 units in stack, so we should get
# warning state if one of unit goes down:
# ./check_nwc_health --hostname 10.10.10.2 --mode ha-status --warning 2:
# OK - stack have 2 units | 'units'=2;2:;0:;;
# and when only one unit left:
# WARNING - stack have 1 units | 'units'=1;2:;0:;;

sub check {
  my ($self) = @_;
  if ($self->{fgHaSystemMode} eq "standalone") {
    $self->add_warning_mitigation("this is a standalone system");
  } else {
    foreach (@{$self->{fgHaStatsTable}}) {
      $_->check();
    }
    $self->set_thresholds(metric => 'num_nodes',
        warning => '2:',
        critical => undef,
    );
    $self->add_info(sprintf "cluster has %d nodes", scalar(@{$self->{fgHaStatsTable}}));
    $self->add_message($self->check_thresholds(metric => 'num_nodes',
        value => scalar(@{$self->{fgHaStatsTable}})));
  }
}


package Classes::Fortigate::Component::HaSubsystem::SyncStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{fgHaStatsSerial} eq $self->{fnSysSerial}) {
    if ($self->mode eq "device::ha::role") {
      $self->{myrole} = $self->{fgHaSystemMode} eq "standalone" ? "master" :
          $self->{fgHaStatsMasterSerial} eq $self->{fnSysSerial} ? "master" : "slave";
      $self->add_info(sprintf "this is a %s node in a %s setup", $self->{myrole}, $self->{fgHaSystemMode});
      if ($self->opts->role ne "master" and $self->opts->role ne "slave") {
        $self->add_unknown('role must be master or slave');
      } elsif ($self->opts->role eq $self->{myrole}) {
        $self->add_ok();
      } else {
        $self->add_critical();
      }
    } elsif ($self->mode eq "device::ha::status") {
      $self->add_info(sprintf "ha sync status is %s", $self->{fgHaStatsSyncStatus});
      if ($self->{fgHaStatsSyncStatus} eq "synchronized") {
        $self->add_ok();
      } else {
        $self->add_critical();
      }
    }
  } else {
    # this row is not relevant for the local node
  }
}

