package CheckNwcHealth::Cumulus;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    #$self->get_snmp_tables("UCD-DISKIO-MIB", [
    #    ['diskios', 'diskIOTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    #]);
    $self->override_opt('warningx', { 'temp_.*' => '68'});
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::LMSENSORSMIB::Component::EnvironmentalSubsystem");
$self->analyze_and_check_environmental_subsystem("CheckNwcHealth::ENTITYSENSORMIB::Component::EnvironmentalSubsystem");

    $self->{components}->{environmental_subsystem} = CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem->new();
    @{$self->{components}->{environmental_subsystem}->{disk_subsystem}->{storages}} = grep {
      $_->{hrStorageDescr} ne '/mnt/root-ro';
    } @{$self->{components}->{environmental_subsystem}->{disk_subsystem}->{storages}} ;
    @{$self->{components}->{environmental_subsystem}->{device_subsystem}->{devices}} = grep {
      $_->{hrDeviceType} ne 'hrDeviceNetwork';
    } @{$self->{components}->{environmental_subsystem}->{device_subsystem}->{devices}} ;
    $self->{components}->{environmental_subsystem}->check();
    $self->{components}->{environmental_subsystem}->dump()
        if $self->opts->verbose >= 2;
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

