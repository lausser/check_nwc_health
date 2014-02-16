package Classes::CiscoIOS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::CiscoIOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::CiscoIOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::CiscoIOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::hsrp/) {
    $self->analyze_and_check_hsrp_subsystem("Classes::HSRP::Component::HSRPSubsystem");
  } elsif ($self->mode =~ /device::users/) {
    $self->analyze_and_check_connection_subsystem("Classes::CiscoIOS::Component::ConnectionSubsystem");
  } elsif ($self->mode =~ /device::config/) {
    $self->analyze_and_check_config_subsystem("Classes::CiscoIOS::Component::ConfigSubsystem");
  } else {
    $self->no_such_mode();
  }
}


