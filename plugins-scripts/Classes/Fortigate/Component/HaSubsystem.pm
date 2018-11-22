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
  if ($self->mode =~ /device::ha::role/) {
    $self->opts->override_opt('role', 'active'); 
    # fgHaSystemMode: activePassive, activeActive or standalone
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
    $self->add_info(sprintf "cluster has %d nodes", scalar(@{$self->{fgHaStatsTable}}));
    $self->add_ok();
  }
}


package Classes::Fortigate::Component::HaSubsystem::SyncStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{fgHaStatsSerial} eq $self->{fnSysSerial}) {
    if ($self->mode eq "device::ha::role") {
      $self->{iammaster} = $self->{fgHaStatsMasterSerial} eq $self->{fnSysSerial} ? 1 : 0;
      $self->add_info(sprintf "this is a %s node in a %s setup", $self->opts->role, $self->{fgHaSystemMode});
      if ($self->opts->role eq "active" && $self->{iammaster}) {
        $self->add_ok();
      } elsif ($self->opts->role eq "passive" && ! $self->{iammaster}) {
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

