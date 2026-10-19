package CheckNwcHealth::OneOS;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

# OneOS (Versatel/1&1) pCPEs, recognized by Device.pm on three anchors:
# sysObjectID under the OneOS device registry (1.3.6.1.4.1.13191.1.1),
# ONEACCESS-SYS-MIB implemented, or a product name starting with "OneOS".
# All OneOS pCPEs share the same data source (ONEACCESS-SYS-MIB,
# oacExpIMSys subtree), so the class chain stops here - there is no
# second-level vendor/model rebless (house precedent QSCAudio/NodeGrid).
# Modes dispatched below read the vendor MIB directly; every other mode
# (uptime, the standard interface modes incl. the LTE uplink) falls back
# to CheckNwcHealth::Generic via no_such_mode(), unchanged.

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::OneOS::Component::EnvironmentalSubsystem");
    $self->reduce_messages_short('environmental hardware working fine');
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::OneOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::OneOS::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

