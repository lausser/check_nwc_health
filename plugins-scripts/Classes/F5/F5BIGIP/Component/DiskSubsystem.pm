package Classes::F5::F5BIGIP::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['disks', 'sysPhysicalDiskTable', 'Classes::F5::F5BIGIP::Component::DiskSubsystem::Disk'],
  ]);
}

package Classes::F5::F5BIGIP::Component::DiskSubsystem::Disk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'disk %s is %s',
      $self->{sysPhysicalDiskName},
      $self->{sysPhysicalDiskArrayStatus});
  if ($self->{sysPhysicalDiskArrayStatus} eq 'failed' && $self->{sysPhysicalDiskIsArrayMember} eq 'false') {
    $self->add_critical();
  } elsif ($self->{sysPhysicalDiskArrayStatus} eq 'failed' && $self->{sysPhysicalDiskIsArrayMember} eq 'true') {
    $self->add_warning();
  }
  # diskname CF* usually has status unknown 
}

