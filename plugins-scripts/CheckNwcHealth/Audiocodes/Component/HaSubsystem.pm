package CheckNwcHealth::Audiocodes::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

  sub init {
     my ($self) = @_;
     # Set default role to "primary" if not specified
     if (! $self->opts->role()) {
       $self->opts->override_opt('role', 'active');
     }
    # Get HA chassis information
    $self->get_snmp_objects('AC-SYSTEM-MIB', qw(
      acSystemChassisHAActiveDevice
      acSystemChassisHADevice1Name
      acSystemChassisHADevice2Name
      acSysHAStatusReady
    ));
    # Get module HA status table
    $self->get_snmp_tables('AC-SYSTEM-MIB', [
      ['module_ha_status', 'acSysModuleTable', 'CheckNwcHealth::Audiocodes::Component::HaSubsystem::ModuleHAStatus', sub { my ($o) = @_; $o->{parent} = $self; }],
    ]);
  }

  sub check {
    my ($self) = @_;
    $self->add_info('checking HA status');

   # Check HA device status
   if (defined $self->{acSystemChassisHAActiveDevice}) {
     my $active_device = $self->{acSystemChassisHAActiveDevice};
     my $device1_name = $self->{acSystemChassisHADevice1Name} || 'device1';
     my $device2_name = $self->{acSystemChassisHADevice2Name} || 'device2';

     $self->add_info(sprintf 'HA active device: %s (%s is active)',
         $active_device, $active_device eq '1' ? $device1_name : $device2_name);
     $self->add_ok();
   } else {
     $self->add_info('HA active device: unknown');
   }

   # Check HA readiness
   if (defined $self->{acSysHAStatusReady}) {
     my $ha_ready = $self->{acSysHAStatusReady};
     $self->add_info(sprintf 'HA status ready: %s', $ha_ready);
     if ($ha_ready eq 'ready' || $ha_ready eq 'notApplicable') {
       $self->add_ok();
     } else {
       $self->add_warning(sprintf 'HA not ready: %s', $ha_ready);
     }
   } else {
     $self->add_info('HA status ready: unknown');
   }

    # Check module HA status
    if (defined $self->{module_ha_status} && ref($self->{module_ha_status}) eq 'ARRAY') {
      foreach (@{$self->{module_ha_status}}) {
        $_->check();
      }
    } else {
      $self->add_info('no module HA status found');
    }
 }

sub xdump {
  my ($self) = @_;
  printf "HA Active Device: %s\n", $self->{acSystemChassisHAActiveDevice} || 'unknown';
  printf "HA Device1 Name: %s\n", $self->{acSystemChassisHADevice1Name} || 'unknown';
  printf "HA Device2 Name: %s\n", $self->{acSystemChassisHADevice2Name} || 'unknown';
  printf "HA Status Ready: %s\n", $self->{acSysHAStatusReady} || 'unknown';
  if (defined $self->{module_ha_status} && ref($self->{module_ha_status}) eq 'ARRAY') {
    foreach (@{$self->{module_ha_status}}) {
      $_->dump();
    }
  }
}

package CheckNwcHealth::Audiocodes::Component::HaSubsystem::ModuleHAStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $index = $self->{flat_indices};
  my $status = $self->{acSysModuleHAStatus};

  # Ignore notApplicable modules
  return if $status eq 'notApplicable';

  $self->add_info(sprintf 'module %s HA status: %s', $index, $status);

  # standAlone is always OK
  if ($status eq 'standAlone') {
    $self->add_ok();
    return;
  }

  # Determine the category of this module's status
  my $module_category;
  if ($status eq 'active' || $status eq 'activeNonHA' || $status eq 'acitveNonHA') {
    $module_category = 'active';
  } elsif ($status eq 'redundant' || $status eq 'redundantNonHA') {
    $module_category = 'redundant';
  } else {
    # Unknown status - treat as critical
    $self->add_critical(sprintf 'module %s HA status: %s (unknown)', $index, $status);
    return;
  }

  # Get the expected role from the parent subsystem
  my $expected_role = $self->{parent}->opts->role();

  # Compare: if matches, OK, otherwise CRITICAL
  if ($module_category eq $expected_role) {
    $self->add_ok();
  } else {
    $self->add_critical(sprintf 'module %s HA status: %s (expected %s)', $index, $status, $expected_role);
  }
}

sub xdump {
  my ($self) = @_;
  printf "module %s HA status: %s\n",
      $self->{flat_indices}, $self->{acSysModuleHAStatus};
}
