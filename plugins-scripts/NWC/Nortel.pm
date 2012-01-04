package NWC::Nortel;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

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
    } elsif ($self->mode =~ /device::interfaces/) {
      $self->analyze_interface_subsystem();
      $self->check_interface_subsystem();
    } elsif ($self->mode =~ /device::shinken::interface/) {
      $self->analyze_interface_subsystem();
      $self->shinken_interface_subsystem();
    } elsif ($self->mode =~ /device::hsrp/) {
      $self->analyze_hsrp_subsystem();
      $self->check_interface_subsystem();
    }
  }
}

sub analyze_hsrp_subsystem {
  my $self = shift;
  $self->{components}->{hsrp} =
      NWC::HSRP::Component::HSRPSubsystem->new();
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      NWC::Nortel::Component::EnvironmentalSubsystem->new();
}

sub analyze_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem} =
      NWC::IFMIB::Component::InterfaceSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      NWC::Nortel::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      NWC::Nortel::Component::MemSubsystem->new();
}

sub check_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem}->check();
  $self->{components}->{environmental_subsystem}->dump()
      if $self->opts->verbose >= 2;
}

sub check_interface_subsystem {
  my $self = shift;
  $self->{components}->{interface_subsystem}->check();
  $self->{components}->{interface_subsystem}->dump()
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

sub shinken_interface_subsystem {
  my $self = shift;
  my $attr = sprintf "%s", join(',', map {
      sprintf '%s$(%s)$$()$', $_->{ifDescr}, $_->{ifIndex}
  } @{$self->{components}->{interface_subsystem}->{interfaces}});
  printf <<'EOEO', $self->opts->hostname(), $self->opts->hostname(), $attr;
define host {
  host_name                     %s
  address                       %s
  use                           default-host
  _interfaces                   %s

}
EOEO
  printf <<'EOEO', $self->opts->hostname();
define service {
  host_name                     %s
  service_description           net_cpu
  check_command                 check_nwc_health!cpu-load!80%%!90%%
}
EOEO
  printf <<'EOEO', $self->opts->hostname();
define service {
  host_name                     %s
  service_description           net_mem
  check_command                 check_nwc_health!memory-usage!80%%!90%%
}
EOEO
  printf <<'EOEO', $self->opts->hostname();
define service {
  host_name                     %s
  service_description           net_ifusage_$KEY$
  check_command                 check_nwc_health!interface-usage!$VALUE1$!$VALUE2$
  duplicate_foreach             _interfaces
  default_value                 80%%|90%%
}
EOEO
}


