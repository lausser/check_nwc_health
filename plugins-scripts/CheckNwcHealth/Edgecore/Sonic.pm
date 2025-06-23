package CheckNwcHealth::Edgecore::Sonic;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Edgecore::Sonic::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_disk_subsystem("CheckNwcHealth::UCDMIB::Component::DiskSubsystem");
# Das Ciscozeug taucht tatsaechlich auf bei einem Geraet, obwohl das nur
# so ein billig zusammengeschustertes 1HU-Glump mit Debian drauf ist.
#  if ($self->implements_mib('CISCO-ENTITY-FRU-CONTROL-MIB')) {
#    $self->analyze_and_check_fru_subsystem("CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::EnvironmentalSubsystem");
#  }
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

