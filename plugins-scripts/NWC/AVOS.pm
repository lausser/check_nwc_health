package NWC::AVOS;

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
      $self->no_such_mode();
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_cpu_subsystem();
      $self->check_cpu_subsystem();
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_mem_subsystem();
      $self->check_mem_subsystem();
    } elsif ($self->mode =~ /device::licenses::/) {
      $self->analyze_key_subsystem();
      $self->check_key_subsystem();
    } elsif ($self->mode =~ /device::connections/) {
      $self->analyze_connection_subsystem();
      $self->check_connection_subsystem();
    } elsif ($self->mode =~ /device::security/) {
      $self->analyze_security_subsystem();
      $self->check_security_subsystem();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      NWC::AVOS::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      NWC::AVOS::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      NWC::AVOS::Component::MemSubsystem->new();
}

sub analyze_key_subsystem {
  my $self = shift;
  $self->{components}->{key_subsystem} =
      NWC::AVOS::Component::KeySubsystem->new();
}

sub analyze_security_subsystem {
  my $self = shift;
  $self->{components}->{security_subsystem} =
      NWC::AVOS::Component::SecuritySubsystem->new();
}

sub analyze_connection_subsystem {
  my $self = shift;
  $self->{components}->{connection_subsystem} =
      NWC::AVOS::Component::ConnectionSubsystem->new();
}

sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      NWC::IFMIB::Component::InterfaceSubsystem->new();
}

sub check_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem}->check();
  $self->{components}->{environmental_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem}->check();
  $self->{components}->{cpu_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem}->check();
  $self->{components}->{mem_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_security_subsystem {
  my $self = shift;
  $self->{components}->{security_subsystem}->check();
  $self->{components}->{security_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_key_subsystem {
  my $self = shift;
  $self->{components}->{key_subsystem}->check();
  $self->{components}->{key_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_connection_subsystem {
  my $self = shift;
  $self->{components}->{connection_subsystem}->check();
  $self->{components}->{connection_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem}->check();
  $self->{components}->{interface_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

