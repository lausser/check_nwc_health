package Classes::CiscoWLC;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::Cisco);

sub init {
  my $self = shift;
  $self->{components} = {
      powersupply_subsystem => undef,
      fan_subsystem => undef,
      temperature_subsystem => undef,
      cpu_subsystem => undef,
      memory_subsystem => undef,
      disk_subsystem => undef,
      environmental_subsystem => undef,
  };
  $self->{serial} = 'unknown';
  $self->{product} = 'unknown';
  $self->{romversion} = 'unknown';
  # serial is 1.3.6.1.2.1.47.1.1.1.1.11.1
  #$self->collect();
  if (! $self->check_messages()) {
    ##$self->set_serial();
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_environmental_subsystem();
      #$self->auto_blacklist();
      $self->check_environmental_subsystem();
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_cpu_subsystem();
      #$self->auto_blacklist();
      $self->check_cpu_subsystem();
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_mem_subsystem();
      #$self->auto_blacklist();
      $self->check_mem_subsystem();
    } elsif ($self->mode =~ /device::wlan/) {
      $self->analyze_wlan_subsystem();
      $self->check_wlan_subsystem();
    } elsif ($self->mode =~ /device::shinken::interface/) {
      $self->analyze_interface_subsystem();
      $self->shinken_interface_subsystem();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      Classes::CiscoWLC::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      Classes::CiscoWLC::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      Classes::CiscoWLC::Component::MemSubsystem->new();
}

sub analyze_wlan_subsystem {
  my $self = shift;
  $self->{components}->{wlan_subsystem} =
      Classes::CiscoWLC::Component::WlanSubsystem->new();
}

