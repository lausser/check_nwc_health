package CheckNwcHealth::Cisco::ASA;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::CISCOENTITYALARMMIB::Component::AlarmSubsystem");
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem");
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::ENTITYSENSORMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Cisco::IOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Cisco::IOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::hsrp/) {
    $self->analyze_and_check_hsrp_subsystem("CheckNwcHealth::HSRP::Component::HSRPSubsystem");
  } elsif ($self->mode =~ /device::users/ || $self->mode =~ /device::connections/) {
    # das war frueher "users". seit 6c70c2627e53cce991181369456c03f630f90f71
    # ist count-connections kein alias von count-users mehr, sondern ein
    # eigenstaendiger mode. fuehrte dazu, dass count-connections hier unten
    # in no_such_mode reinlief. daher dieses users||connections.
    # weil es sich bei asa tatsaechlich eher um connections als users handelt,
    # waere es sauber, das users rauszuwerfen, allerdings wuerde das dann
    # bei denen krachen, die count-users verwenden.
    $self->analyze_and_check_connection_subsystem("CheckNwcHealth::Cisco::IOS::Component::ConnectionSubsystem");
  } elsif ($self->mode =~ /device::config/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Cisco::IOS::Component::ConfigSubsystem");
  } elsif ($self->mode =~ /device::interfaces::nat::sessions::count/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Cisco::IOS::Component::NatSubsystem");
  } elsif ($self->mode =~ /device::interfaces::nat::rejects/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Cisco::IOS::Component::NatSubsystem");
  } elsif ($self->mode =~ /device::vpn::status/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem");
  } elsif ($self->mode =~ /device::vpn::sessions/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Cisco::CISCOREMOTEACCESSMONITORMIB::Component::VpnSubsystem");
  } elsif ($self->mode =~ /device::ha::role/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Cisco::IOS::Component::HaSubsystem");
  } else {
    $self->no_such_mode();
  }
}


