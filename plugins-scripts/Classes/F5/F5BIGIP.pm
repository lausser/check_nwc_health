package Classes::F5::F5BIGIP;
our @ISA = qw(Classes::F5);
use strict;

sub init {
  my ($self) = @_;
  # gets 11.* and 9.*
  $self->{sysProductVersion} = $self->get_snmp_object('F5-BIGIP-SYSTEM-MIB', 'sysProductVersion');
  $self->{sysPlatformInfoMarketingName} = $self->get_snmp_object('F5-BIGIP-SYSTEM-MIB', 'sysPlatformInfoMarketingName');
  if (! defined $self->{sysProductVersion} ||
      $self->{sysProductVersion} !~ /^((9)|(10)|(11)|(12)|(13)|(14)|(15)|(16))/) {
    $self->{sysProductVersion} = "4";
  }
  if ($self->mode =~ /device::hardware::health/) {
    if (! $self->get_snmp_object('F5-BIGIP-SYSTEM-MIB', 'sysChassisFanNumber') &&
        ! $self->get_snmp_object('F5-BIGIP-SYSTEM-MIB', 'sysChassisPowerSupplyNumber')) {
      $self->analyze_and_check_environmental_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
    } else {
      $self->analyze_and_check_environmental_subsystem("Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem");
    }
    $self->analyze_and_check_environmental_subsystem("Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::F5::F5BIGIP::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::F5::F5BIGIP::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::lb/) {
    if ($self->opts->role && $self->opts->role eq "gtm") {
      $self->analyze_and_check_gtm_subsystem("Classes::F5::F5BIGIP::Component::GTMSubsystem");
    } else {
      $self->analyze_and_check_ltm_subsystem();
    }
  } elsif ($self->mode =~ /device::wideip/) {
    $self->analyze_and_check_gtm_subsystem("Classes::F5::F5BIGIP::Component::GTMSubsystem");
  } elsif ($self->mode =~ /device::users::count/) {
    $self->analyze_and_check_connection_subsystem("Classes::F5::F5BIGIP::Component::ConnectionSubsystem");
  } elsif ($self->mode =~ /device::connections::count/) {
    $self->analyze_and_check_connection_subsystem("Classes::F5::F5BIGIP::Component::ConnectionSubsystem");
  } elsif ($self->mode =~ /device::config/) {
    $self->analyze_and_check_config_subsystem("Classes::F5::F5BIGIP::Component::ConfigSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("Classes::F5::F5BIGIP::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::vip/) {
    $self->analyze_and_check_vip_subsystem("Classes::F5::F5BIGIP::Component::VipSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub analyze_ltm_subsystem {
  my ($self) = @_;
  $self->{components}->{ltm_subsystem} =
      Classes::F5::F5BIGIP::Component::LTMSubsystem->new('sysProductVersion' => $self->{sysProductVersion}, sysPlatformInfoMarketingName => $self->{sysPlatformInfoMarketingName});
}

