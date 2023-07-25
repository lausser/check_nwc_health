package CheckNwcHealth::Juniper::SRX;
our @ISA = qw(CheckNwcHealth::Juniper);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Juniper::SRX::Component::EnvironmentalSubsystem");
    $self->{components}->{hostresource_subsystem} =
        CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem->new();
    foreach (@{$self->{components}->{hostresource_subsystem}->{disk_subsystem}->{storages}}) {
      if (exists $_->{device} && $_->{device} =~ /^(\/dev\/md|junosprocfs)/) {
        $_->blacklist();
      }
    }
    $self->{components}->{hostresource_subsystem}->check();
    $self->{components}->{hostresource_subsystem}->dump()
        if $self->opts->verbose >= 2;
    $self->clear_ok();
    if (! $self->check_messages()) {
      $self->add_ok("environmental hardware working fine");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Juniper::SRX::Component::CpuSubsystem");
    #$self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Juniper::SRX::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

