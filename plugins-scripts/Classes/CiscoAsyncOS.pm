package Classes::CiscoAsyncOS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem();
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem();
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem();
  } elsif ($self->mode =~ /device::licenses::/) {
    $self->analyze_and_check_key_subsystem();
  } else {
    $self->no_such_mode();
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      Classes::CiscoAsyncOS::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      Classes::CiscoAsyncOS::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      Classes::CiscoAsyncOS::Component::MemSubsystem->new();
}

sub analyze_key_subsystem {
  my $self = shift;
  $self->{components}->{key_subsystem} =
      Classes::CiscoAsyncOS::Component::KeySubsystem->new();
}

