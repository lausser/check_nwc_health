package Classes::Alcatel::OmniAccess;
our @ISA = qw(Classes::Alcatel);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Alcatel::OmniAccess::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Alcatel::OmniAccess::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Alcatel::OmniAccess::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::wlan/) {
    $self->analyze_and_check_wlan_subsystem("Classes::Alcatel::OmniAccess::Component::WlanSubsystem");
  } else {
    $self->no_such_mode();
  }
}

