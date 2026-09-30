package CheckNwcHealth::QSCAudio::Component::InventorySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;


# Q-SYS publishes every item in the loaded design in inventoryTable.
# invDeviceStatus is the vendor's human-readable state; the accompanying
# invDeviceStatusValue has no enum in the MIB, so it is reported for
# diagnosis but is deliberately not used to infer health.

sub init {
  my ($self) = @_;
  # --name (and --regexp) selects the inventory devices whose
  # invDeviceName or invDeviceType matches the selection. The standard
  # filter_name() carries the family-wide selection semantics (case-
  # insensitive exact match in plain mode, case-insensitive regex with
  # --regexp) and is applied to both attributes; without --name it
  # selects every row, leaving the unfiltered path untouched.
  $self->get_snmp_tables('QSCAUDIO-MIB', [
    ['inventory_devices', 'inventoryTable',
      'CheckNwcHealth::QSCAudio::Component::InventorySubsystem::InventoryDevice',
      sub { my ($o) = @_;
            $self->filter_name($o->{invDeviceName} // '')
            || $self->filter_name($o->{invDeviceType} // '') }],
  ]);
}

sub check {
  my ($self) = @_;
  my $name = $self->opts->name;
  if (!@{$self->{inventory_devices}}) {
    if (defined $name && length $name) {
      $self->add_unknown('no inventory device matched the selection');
    } else {
      $self->add_unknown('no Q-SYS inventory devices found');
    }
    return;
  }
  $self->add_info('checking Q-SYS inventory devices');
  foreach (@{$self->{inventory_devices}}) {
    $_->check();
  }
}

sub dump {
  my ($self) = @_;
  foreach (@{$self->{inventory_devices}}) {
    $_->dump();
  }
}

package CheckNwcHealth::QSCAudio::Component::InventorySubsystem::InventoryDevice;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;

  if (!defined $self->{invDeviceStatus}) {
    $self->add_unknown(sprintf 'inventory device %s (%s) has no status',
        $self->{invDeviceName} || $self->{flat_indices},
        $self->{invDeviceType} || 'unknown type');
    return;
  }

  my $message = sprintf 'inventory device %s (%s) status is %s%s',
      $self->{invDeviceName} || $self->{flat_indices},
      $self->{invDeviceType} || 'unknown type',
      $self->{invDeviceStatus},
      defined($self->{invDeviceStatusValue}) ?
          sprintf(' (value %s)', $self->{invDeviceStatusValue}) : '';
  $self->add_info($message);
  if (uc($self->{invDeviceStatus}) eq 'OK') {
    $self->add_ok();
  } else {
    $self->add_critical($message);
  }
}

sub dump {
  my ($self) = @_;
  printf "inventory device %s (%s) status is %s%s\n",
      $self->{invDeviceName} || $self->{flat_indices},
      $self->{invDeviceType} || 'unknown type',
      defined($self->{invDeviceStatus}) ? $self->{invDeviceStatus} : 'unknown',
      defined($self->{invDeviceStatusValue}) ?
          sprintf(' (value %s)', $self->{invDeviceStatusValue}) : '';
}
