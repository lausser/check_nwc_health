package Classes::Cisco::IOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->implements_mib('CISCO-ENHANCED-MEMPOOL-MIB')) {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem");
    if (! exists $self->{components}->{mem_subsystem} ||
        scalar(@{$self->{components}->{mem_subsystem}->{mems}}) == 0) {
      # satz mix x....
      # der hier: Cisco IOS Software, IOS-XE Software, Catalyst L3 Switch Software (CAT3K_CAA-UNIVERSALK9-M), Version 03.03.02SE RELEASE SOFTWARE (fc2)
      # hat nicht mehr zu bieten als eine einzige oid
      # cempMemBufferNotifyEnabled .1.3.6.1.4.1.9.9.221.1.2.1.0 = INTEGER: 2
      # deshalb:
      $self->analyze_and_check_mem_subsystem("Classes::Cisco::CISCOMEMORYPOOLMIB::Component::MemSubsystem");
    }
  } else {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::CISCOMEMORYPOOLMIB::Component::MemSubsystem");
  }
}

