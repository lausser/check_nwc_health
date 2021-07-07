package Classes::CheckPoint::Firewall1;
our @ISA = qw(Classes::CheckPoint);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::CheckPoint::Firewall1::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::CheckPoint::Firewall1::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::CheckPoint::Firewall1::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("Classes::CheckPoint::Firewall1::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::fw::/) {
    $self->analyze_and_check_fw_subsystem("Classes::CheckPoint::Firewall1::Component::FwSubsystem");
  } elsif ($self->mode =~ /device::svn::/) {
    $self->analyze_and_check_svn_subsystem("Classes::CheckPoint::Firewall1::Component::SvnSubsystem");
  } elsif ($self->mode =~ /device::mngmt::/) {
    # not sure if this works fa25239716cb74c672f8dd390430dc4056caffa7
    $self->analyze_and_check_mngmt_subsystem("Classes::CheckPoint::Firewall1::Component::MngmtSubsystem");
  } elsif ($self->mode =~ /device::vpn::status/) {
    $self->analyze_and_check_config_subsystem("Classes::CheckPoint::Firewall1::Component::VpnSubsystem");
  } elsif ($self->mode =~ /device::vpn::sessions/) {
    $self->analyze_and_check_config_subsystem("Classes::CheckPoint::Firewall1::Component::VpnSessions");
  } else {
    $self->no_such_mode();
  }
}

