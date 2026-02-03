package CheckNwcHealth::Audiocodes;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

# Audiocodes Session Border Controllers (SBC)

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Audiocodes::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Audiocodes::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Audiocodes::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::disk::usage/) {
    $self->analyze_and_check_disk_subsystem("CheckNwcHealth::Audiocodes::Component::DiskSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("CheckNwcHealth::Audiocodes::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::sbc::license/) {
    $self->analyze_and_check_sbc_subsystem("CheckNwcHealth::Audiocodes::Component::SbcLicenseSubsystem");
  } elsif ($self->mode =~ /device::sbc::media/) {
    $self->analyze_and_check_sbc_subsystem("CheckNwcHealth::Audiocodes::Component::SbcMediaSubsystem");
  } elsif ($self->mode =~ /device::sbc::dsp/) {
    $self->analyze_and_check_sbc_subsystem("CheckNwcHealth::Audiocodes::Component::SbcDspSubsystem");
  } elsif ($self->mode =~ /device::sbc::call/) {
    $self->analyze_and_check_sbc_subsystem("CheckNwcHealth::Audiocodes::Component::SbcCallSubsystem");
  } elsif ($self->mode =~ /device::sbc::cluster/) {
    $self->analyze_and_check_sbc_subsystem("CheckNwcHealth::Audiocodes::Component::SbcClusterSubsystem");
  } else {
    $self->no_such_mode();
  }
}

