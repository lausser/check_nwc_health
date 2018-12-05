package Classes::Cisco::IOS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::chassis::health/) {
    if ($self->implements_mib('CISCO-STACK-MIB')) {
      $self->analyze_and_check_environmental_subsystem("Classes::Cisco::CISCOSTACKMIB::Component::StackSubsystem");
    } elsif ($self->implements_mib('CISCO-STACKWISE-MIB')) {
      $self->analyze_and_check_environmental_subsystem("Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem");
    }
    if (! $self->implements_mib('CISCO-STACKWISE-MIB') &&
        !  $self->implements_mib('CISCO-STACK-MIB')) {
      if (defined $self->opts->mitigation()) {
        $self->add_message($self->opts->mitigation(), 'this is not a stacked device');
      } else {
        $self->add_unknown('this is not a stacked device');
      }
    }
  } elsif ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Cisco::IOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Cisco::IOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::IOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::hsrp/) {
    $self->analyze_and_check_hsrp_subsystem("Classes::HSRP::Component::HSRPSubsystem");
  } elsif ($self->mode =~ /device::users/) {
    $self->analyze_and_check_connection_subsystem("Classes::Cisco::IOS::Component::ConnectionSubsystem");
  } elsif ($self->mode =~ /device::config/) {
    $self->analyze_and_check_config_subsystem("Classes::Cisco::IOS::Component::ConfigSubsystem");
  } elsif ($self->mode =~ /device::interfaces::nat::sessions::count/) {
    $self->analyze_and_check_config_subsystem("Classes::Cisco::IOS::Component::NatSubsystem");
  } elsif ($self->mode =~ /device::interfaces::nat::rejects/) {
    $self->analyze_and_check_config_subsystem("Classes::Cisco::IOS::Component::NatSubsystem");
  #} elsif ($self->mode =~ /device::bgp::prefix::count/) {
  } elsif ($self->mode =~ /device::bgp/) {
    $self->analyze_and_check_bgp_subsystem("Classes::BGP::Component::PeerSubsystem");
  } elsif ($self->mode =~ /device::wlan/ && $self->implements_mib('AIRESPACE-WIRELESS-MIB')) {
      $self->analyze_and_check_wlan_subsystem("Classes::Cisco::WLC::Component::WlanSubsystem");
  } elsif ($self->mode =~ /device::vpn::status/) {
    $self->analyze_and_check_config_subsystem("Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem");
  } else {
    $self->no_such_mode();
  }
}


