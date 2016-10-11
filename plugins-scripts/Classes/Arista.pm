package Classes::Arista;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->mult_snmp_max_msg_size(10);
    $self->analyze_and_check_environmental_subsystem("Classes::Arista::Component::EnvironmentalSubsystem");
    if (! $self->check_messages()) {
      $self->clear_messages(0);
      $self->add_ok("environmental hardware working fine");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    # CPU util on management plane
    # Utilization of CPUs on dataplane that are used for system functions
    $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::HOSTRESOURCESMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("Classes::Arista::Component::HaSubsystem");
  } else {
    $self->no_such_mode();
  }
}

