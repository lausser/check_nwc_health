package CheckNwcHealth::QSCAudio;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


# Q-SYS Audio (QSC) devices are Linux-based DSP processors running a
# UCD-SNMP agent; they are detected via QSCAUDIO-MIB (QSC enterprise
# sysObjectID 1.3.6.1.4.1.1536.1.1) in CheckNwcHealth::Device::classify()
# and must not fall through to the generic-Linux handling there.
# Mode dispatch: cpu-load and memory-usage reuse the standard UCD-SNMP
# components; hardware-health evaluates the Q-SYS inventory-device
# states from QSCAUDIO-MIB. Q-SYS devices need not expose UCD disk rows.

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    # hardware-health = Q-SYS inventory status. Do not run the generic
    # UCD disk check: a Q-SYS device without disks is a valid appliance.
    $self->analyze_and_check_inventory_subsystem("CheckNwcHealth::QSCAudio::Component::InventorySubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::UCDMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}
