package Classes::CiscoCCM;
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
  } elsif ($self->mode =~ /device::phone::cm/) {
    $self->analyze_and_check_cm_subsystem();
  } elsif ($self->mode =~ /device::phone/) {
    $self->analyze_and_check_phone_subsystem();
  } else {
    $self->no_such_mode();
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::MemSubsystem->new();
}

sub analyze_phone_subsystem {
  my $self = shift;
  $self->{components}->{phone_subsystem} =
      Classes::CiscoCCM::Component::PhoneSubsystem->new();
}

sub analyze_cm_subsystem {
  my $self = shift;
  $self->{components}->{cm_subsystem} =
      Classes::CiscoCCM::Component::CmSubsystem->new();
}

