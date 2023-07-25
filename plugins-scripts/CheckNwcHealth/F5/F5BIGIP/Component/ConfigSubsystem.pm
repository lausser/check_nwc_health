package CheckNwcHealth::F5::F5BIGIP::Component::ConfigSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my $self = shift;
  $self->get_snmp_objects('F5-BIGIP-SYSTEM-MIB', (qw(sysCmSyncStatusId sysCmSyncStatusColor sysCmSyncStatusSummary)));
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
    ['details', 'sysCmSyncStatusDetailsTable', 'CheckNwcHealth::F5::F5BIGIP::Component::ConfigSubsystem::Details'],
  ]);

  # using role=standalone to adjust the check for clustered/standalone configurations
  if (! $self->opts->role()) {
    $self->opts->override_opt('role', 'active'); # active/standby/standalone
  }
}

sub check {
  my $self = shift;
  my $info;

  $self->add_info(sprintf "config sync state is %s (%s)\n%s",
    $self->{sysCmSyncStatusId},
    $self->{sysCmSyncStatusColor},
    $self->{sysCmSyncStatusSummary}
  );

  # The sync status ID on the system.
  # 0 unknown - the device is disconnected from the device group;
  # 1 syncing - the device is joining the device group or has requested changes from device group or inconsistent with the group;
  # 2 needManualSync - changes have been made on the device not syncd to the device group;
  # 3 inSync - the device is consistent with the device group
  # 4 syncFailed - the device is inconsistent with the device group, requires user intervention;
  # 5 syncDisconnected - the device is not connected to any peers;
  # 6 standalone - the device is in a standalone configuration;
  # 7 awaitingInitialSync - the device is waiting for initial sync;
  # 8 incompatibleVersion - the device's version is incompatible with rest of the devices in the device group;
  # 9 partialSync - some but not all devices successfully received the last sync."
  if ( $self->{sysCmSyncStatusId} eq 'inSync' ) {
    # inSync
    if ( $self->opts->role() eq 'standalone' ) {
      $self->add_warning(sprintf "Unexpected sync status for standalone node: %s (%s)",
        $self->{sysCmSyncStatusId}, $self->{sysCmSyncStatusColor});
    } else {
      $self->add_ok();
    }
  } elsif ( $self->{sysCmSyncStatusId} eq 'standalone' ) {
    # standalone
    if ( $self->opts->role() eq 'standalone' ) {
      $self->add_ok();
    } else {
      $self->add_critical_mitigation();
    }
  } else {
    # everything else - error
    $self->add_critical_mitigation();
  }

  foreach (@{$self->{details}}) {
    $_->check();
  }
}

package CheckNwcHealth::F5::F5BIGIP::Component::ConfigSubsystem::Details;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;

  $self->add_ok(sprintf "%d: %s",
    $self->{sysCmSyncStatusDetailsIndex},
    $self->{sysCmSyncStatusDetailsDetails},
  );
}

