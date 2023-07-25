package CheckNwcHealth::Cisco::NXOS;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    #$self->mult_snmp_max_msg_size(10);
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::NXOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::cisco::fex::watch/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::NXOS::Component::FexSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Cisco::IOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Cisco::NXOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::config/) {
    $self->analyze_and_check_config_subsystem("CheckNwcHealth::Cisco::IOS::Component::ConfigSubsystem");
  } elsif ($self->mode =~ /device::hsrp/) {
    $self->analyze_and_check_hsrp_subsystem("CheckNwcHealth::HSRP::Component::HSRPSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  if ($sysDescr =~ /(Cisco NX-OS.*? n\d+),.*(Version .*), RELEASE SOFTWARE/) {
    return $1.' '.$2;
  }
}
