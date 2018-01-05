package Classes::PaloAlto;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_environmental_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
    # entity-state-mib gibts u.u. auch
    # The entStateTable will have entries for Line Cards, Fan Trays and Power supplies. Since these entities only apply to chassis systems, only PA-7000 series devices will support this MIB.
    # gibts aber erst, wenn einer die entwicklung zahlt. bis dahin ist es
    # mir scheissegal, wenn euch die firewalls abkacken, ihr freibiervisagen
  } elsif ($self->mode =~ /device::hardware::load/) {
    # CPU util on management plane
    # Utilization of CPUs on dataplane that are used for system functions
    $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::HOSTRESOURCESMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("Classes::PaloAlto::Component::HaSubsystem");
  } else {
    $self->no_such_mode();
  }
}

