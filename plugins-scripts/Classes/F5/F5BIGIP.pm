package Classes::F5::F5BIGIP;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::F5);

sub init {
  my $self = shift;
  my %params = @_;
  $self->{components} = {
      powersupply_subsystem => undef,
      fan_subsystem => undef,
      temperature_subsystem => undef,
      cpu_subsystem => undef,
      memory_subsystem => undef,
      disk_subsystem => undef,
      environmental_subsystem => undef,
      ltm_subsystem => undef,
  };
  # gets 11.* and 9.*
  $self->{productversion} = $self->get_snmp_object('F5-BIGIP-SYSTEM-MIB', 'sysProductVersion');
  if (! defined $self->{productversion} ||
      $self->{productversion} !~ /^((9)|(10)|(11))/) {
    $self->{productversion} = "4";
  }
  $params{productversion} = $self->{productversion};
  if (! $self->check_messages()) {
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
    } elsif ($self->mode =~ /device::lb/) {
      $self->analyze_ltm_subsystem(%params);
      $self->check_ltm_subsystem();
    } elsif ($self->mode =~ /device::shinken::interface/) {
      $self->analyze_interface_subsystem();
      $self->shinken_interface_subsystem();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      Classes::F5::F5BIGIP::Component::CpuSubsystem->new();
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      Classes::F5::F5BIGIP::Component::MemSubsystem->new();
}

sub analyze_ltm_subsystem {
  my $self = shift;
  my %params = @_;
  $self->{components}->{ltm_subsystem} =
      Classes::F5::F5BIGIP::Component::LTMSubsystem->new(%params);
}

