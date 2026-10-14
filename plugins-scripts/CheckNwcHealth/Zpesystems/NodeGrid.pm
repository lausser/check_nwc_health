package CheckNwcHealth::Zpesystems::NodeGrid;
our @ISA = qw(CheckNwcHealth::Zpesystems);
use strict;


# ZPE Systems Nodegrid appliances (console servers / SR routers).
# Mode dispatch:
# hardware-health = power supplies, CPU/system temperature, SSD life,
# power consumption and the optional external sensors, all from
# Nodegrid-MIB.
# cpu-load and memory-usage: Nodegrid-MIB has no utilization values.
# If the device answers the ZPE ZSW-228-MIB, its cpu/memory values are
# used, otherwise the standard HOST-RESOURCES-/UCD-SNMP-MIB components.

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem");
    $self->reduce_messages_short('environmental hardware working fine');
  } elsif ($self->mode =~ /device::hardware::load/) {
    # hrProcessorLoad is a 1-minute average per core and needs no state
    # file. UCD (ssCpuRaw counters) needs two runs, so it comes last.
    if ($self->implements_mib('ZSW-228-MIB')) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Zpesystems::NodeGrid::Component::CpuSubsystem");
    } elsif ($self->implements_mib('HOST-RESOURCES-MIB', 'hrProcessorTable')) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
    } elsif ($self->implements_mib('UCD-SNMP-MIB')) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::CpuSubsystem");
    } else {
      $self->no_such_mode();
    }
  } elsif ($self->mode =~ /device::hardware::memory/) {
    # UCD before HOST-RESOURCES, because UCD does not count buffers and
    # cache as used memory.
    if ($self->implements_mib('ZSW-228-MIB')) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Zpesystems::NodeGrid::Component::MemSubsystem");
    } elsif ($self->implements_mib('UCD-SNMP-MIB')) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::UCDMIB::Component::MemSubsystem");
    } elsif ($self->implements_mib('HOST-RESOURCES-MIB', 'hrStorageTable')) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
    } else {
      $self->no_such_mode();
    }
  } else {
    $self->no_such_mode();
  }
}

