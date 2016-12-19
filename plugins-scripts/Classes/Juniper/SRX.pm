package Classes::Juniper::SRX;
our @ISA = qw(Classes::Juniper);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Juniper::SRX::Component::EnvironmentalSubsystem");
    $self->{components}->{hostresource_subsystem} =
        Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem->new();
    foreach (@{$self->{components}->{hostresource_subsystem}->{disk_subsystem}->{storages}}) {
      if (exists $_->{device} && $_->{device} =~ /^\/dev\/md/) {
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
    $self->analyze_and_check_cpu_subsystem("Classes::Juniper::SRX::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Juniper::SRX::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

