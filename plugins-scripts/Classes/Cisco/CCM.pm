package Classes::Cisco::CCM;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::HOSTRESOURCESMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::phone::cm/) {
    $self->analyze_and_check_cm_subsystem("Classes::Cisco::CCM::Component::CmSubsystem");
  } elsif ($self->mode =~ /device::phone/) {
    $self->analyze_and_check_phone_subsystem("Classes::Cisco::CCM::Component::PhoneSubsystem");
  } else {
    $self->no_such_mode();
  }
}

