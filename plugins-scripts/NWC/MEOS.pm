package NWC::MEOS;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Brocade);

sub init {
  my $self = shift;
  my %params = @_;
  $self->SUPER::init(%params);
  $self->{components} = {
      powersupply_subsystem => undef,
      fan_subsystem => undef,
      temperature_subsystem => undef,
      cpu_subsystem => undef,
  };
  $self->{serial} = 'unknown';
  $self->{product} = 'unknown';
  $self->{romversion} = 'unknown';
  # serial is 1.3.6.1.2.1.47.1.1.1.1.11.1
  #$self->collect();
  if (! $self->check_messages()) {
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_environmental_subsystem();
      $self->check_environmental_subsystem();
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_cpu_subsystem();
      $self->check_cpu_subsystem();
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_mem_subsystem();
      $self->check_mem_subsystem();
    } elsif ($self->mode =~ /device::interfaces/) {
      $self->analyze_interface_subsystem();
      $self->check_interface_subsystem();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem1} =
      NWC::FCMGMT::Component::EnvironmentalSubsystem->new();
  $self->{components}->{environmental_subsystem2} =
      NWC::FCEOS::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->no_such_mode();
  $self->{components}->{cpu_subsystem} =
      NWC::UCDMIB::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->no_such_mode();
  $self->{components}->{mem_subsystem} =
      NWC::UCDMIB::Component::MemSubsystem->new();
}

sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      NWC::IFMIB::Component::InterfaceSubsystem->new();
}

sub check_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem1}->check();
  $self->{components}->{environmental_subsystem2}->check();
  if ($self->check_messages()) {
    $self->clear_messages(OK);
  }
  $self->{components}->{environmental_subsystem1}->dump()
      if $self->opts->verbose >= 2;
  $self->{components}->{environmental_subsystem2}->dump()
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

sub check_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem}->check();
  $self->{components}->{interface_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

