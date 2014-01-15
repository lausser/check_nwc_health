package NWC::SGOS;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Bluecoat);

sub init {
  my $self = shift;
  my %params = @_;
  $self->{components} = {
      powersupply_subsystem => undef,
      fan_subsystem => undef,
      temperature_subsystem => undef,
      cpu_subsystem => undef,
      security_subsystem => undef,
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
      $self->check_environmental_subsystem();
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_cpu_subsystem();
      $self->check_cpu_subsystem();
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_mem_subsystem();
      $self->check_mem_subsystem();
    } elsif ($self->mode =~ /device::security/) {
      $self->analyze_security_subsystem();
      $self->check_security_subsystem();
    } elsif ($self->mode =~ /device::(users|connections)::count/) {
      $self->analyze_connection_subsystem();
      $self->check_connection_subsystem();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      NWC::SGOS::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      NWC::SGOS::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      NWC::SGOS::Component::MemSubsystem->new();
}

sub analyze_security_subsystem {
  my $self = shift;
  $self->{components}->{security_subsystem} =
      NWC::SGOS::Component::SecuritySubsystem->new();
}

sub analyze_connection_subsystem {
  my $self = shift;
  $self->{components}->{connection_subsystem} =
      NWC::SGOS::Component::ConnectionSubsystem->new();
}

