package CheckNwcHealth::Cisco::CCM;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::phone::cm/) {
    $self->analyze_and_check_cm_subsystem("CheckNwcHealth::Cisco::CCM::Component::CmSubsystem");
  } elsif ($self->mode =~ /device::phone/) {
    $self->analyze_and_check_phone_subsystem("CheckNwcHealth::Cisco::CCM::Component::PhoneSubsystem");
  } else {
    $self->no_such_mode();
  }
}

