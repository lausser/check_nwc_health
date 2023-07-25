package CheckNwcHealth::Bintec::Bibo::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->bulk_is_baeh();
  $self->get_snmp_tables('BINTEC-FILESYS', [
      ['disks', 'fsDiskTable', 'CheckNwcHealth::Bintec::Bibo::Component::DiskSubsystem::Disk'],
  ]);
}


package CheckNwcHealth::Bintec::Bibo::Component::DiskSubsystem::Disk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{usage} = 100 - (100 * $self->{fsDiskFreeBlocks} / $self->{fsDiskBlocks});
}

sub check {
  my ($self) = @_;
  my $label = 'disk_'.$self->{fsDiskDevName};
  $self->add_info(sprintf 'disk %s usage is %.2f%%',
      $self->{fsDiskDevName},
      $self->{usage});
  $self->set_thresholds(metric => $label, warning => '85', critical => '90');
  $self->add_message($self->check_thresholds(metric => $label, value => $self->{usage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{usage},
      uom => '%',
  );
  $self->add_info(sprintf 'disk %s status is %s',
      $self->{fsDiskDevName},
      $self->{fsDiskStatus});
  
  if ($self->{fsDiskStatus} eq "error") {
    $self->add_critical();
  }
}


