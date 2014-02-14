package Classes::AVOS;
our @ISA = qw(Classes::Bluecoat);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem();
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem();
  } elsif ($self->mode =~ /device::licenses::/) {
    $self->analyze_and_check_key_subsystem();
  } elsif ($self->mode =~ /device::connections/) {
    $self->analyze_and_check_connection_subsystem();
  } elsif ($self->mode =~ /device::security/) {
    $self->analyze_and_check_security_subsystem();
  } else {
    $self->no_such_mode();
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      Classes::AVOS::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      Classes::AVOS::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      Classes::AVOS::Component::MemSubsystem->new();
}

sub analyze_key_subsystem {
  my $self = shift;
  $self->{components}->{key_subsystem} =
      Classes::AVOS::Component::KeySubsystem->new();
}

sub analyze_security_subsystem {
  my $self = shift;
  $self->{components}->{security_subsystem} =
      Classes::AVOS::Component::SecuritySubsystem->new();
}

sub analyze_connection_subsystem {
  my $self = shift;
  $self->{components}->{connection_subsystem} =
      Classes::AVOS::Component::ConnectionSubsystem->new();
}

