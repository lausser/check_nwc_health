package NWC::CiscoCCM;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Cisco);

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
      phone_subsystem => undef,
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
    } elsif ($self->mode =~ /device::phone::cm/) {
      $self->analyze_cm_subsystem();
      $self->check_cm_subsystem();
    } elsif ($self->mode =~ /device::phone/) {
      $self->analyze_phone_subsystem();
      $self->check_phone_subsystem();
    } else {
      $self->no_such_mode();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      NWC::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      NWC::HOSTRESOURCESMIB::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      NWC::HOSTRESOURCESMIB::Component::MemSubsystem->new();
}

sub analyze_phone_subsystem {
  my $self = shift;
  $self->{components}->{phone_subsystem} =
      NWC::CiscoCCM::Component::PhoneSubsystem->new();
}

sub analyze_cm_subsystem {
  my $self = shift;
  $self->{components}->{cm_subsystem} =
      NWC::CiscoCCM::Component::CmSubsystem->new();
}

