package Classes::CheckPoint::Firewall1;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::CheckPoint);

sub init {
  my $self = shift;
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
    ##$self->set_serial();
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_environmental_subsystem();
      $self->check_environmental_subsystem();
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_cpu_subsystem();
      $self->check_cpu_subsystem();
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_mem_subsystem();
      $self->check_mem_subsystem();
    } elsif ($self->mode =~ /device::ha::/) {
      $self->analyze_ha_subsystem();
      $self->check_ha_subsystem();
    } elsif ($self->mode =~ /device::fw::/) {
      $self->analyze_fw_subsystem();
      $self->check_fw_subsystem();
    } elsif ($self->mode =~ /device::svn::/) {
      $self->analyze_svn_subsystem();
      $self->check_svn_subsystem();
    } elsif ($self->mode =~ /device::mngmt::/) {
      $self->analyze_mngmt_subsystem();
      $self->check_svn_subsystem();
    }
  }
}

sub analyze_environmental_subsystem {
  my $self = shift;
  $self->{components}->{environmental_subsystem} =
      Classes::CheckPoint::Firewall1::Component::EnvironmentalSubsystem->new();
}

sub analyze_cpu_subsystem {
  my $self = shift;
  $self->{components}->{cpu_subsystem} =
      Classes::CheckPoint::Firewall1::Component::CpuSubsystem->new();
#printf "%s\n", Data::Dumper::Dumper($self->{components});
}

sub analyze_mem_subsystem {
  my $self = shift;
  $self->{components}->{mem_subsystem} =
      Classes::CheckPoint::Firewall1::Component::MemSubsystem->new();
}

sub analyze_ha_subsystem {
  my $self = shift;
  $self->{components}->{ha_subsystem} =
      Classes::CheckPoint::Firewall1::Component::HaSubsystem->new();
}

sub analyze_fw_subsystem {
  my $self = shift;
  $self->{components}->{fw_subsystem} =
      Classes::CheckPoint::Firewall1::Component::FwSubsystem->new();
}

sub analyze_svn_subsystem {
  my $self = shift;
  $self->{components}->{svn_subsystem} =
      Classes::CheckPoint::Firewall1::Component::SvnSubsystem->new();
}

sub analyze_mngmt_subsystem {
  my $self = shift;
  $self->{components}->{mngmt_subsystem} =
      Classes::CheckPoint::Firewall1::Component::MngmtSubsystem->new();
}

