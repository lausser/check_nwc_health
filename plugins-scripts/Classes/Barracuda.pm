package Classes::Barracuda;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->bulk_is_baeh(5);
    $self->analyze_and_check_environmental_subsystem("Classes::Barracuda::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::UCDMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::UCDMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::fw::policy::connections/) {
    $self->analyze_and_check_fw_subsystem("Classes::Barracuda::Component::FwSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_fw_subsystem("Classes::Barracuda::Component::HaSubsystem");
  } else {
    # Merkwuerdigerweise gibts ohne das hier einen Timeout bei
    # IP-FORWARD-MIB::inetCidrRouteTable und den route-Modi
    if ($self->mode() =~ /device::routes/) {
      $self->mult_snmp_max_msg_size(40);
      $self->bulk_is_baeh(5);
    } else {
      $self->reset_snmp_max_msg_size();
    }
    $self->no_such_mode();
  }
}
