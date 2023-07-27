package CheckNwcHealth::Alcatel::OmniAccess::Component::StorageSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('WLSX-SYSTEMEXT-MIB', [
      ['storage', 'wlsxSysExtStorageTable', 'CheckNwcHealth::Alcatel::OmniAccess::Component::StorageSubsystem::Storageory'],
  ]);
}


package CheckNwcHealth::Alcatel::OmniAccess::Component::StorageSubsystem::Storageory;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{usage} = 100 * $self->{sysExtStorageUsed} / $self->{sysExtStorageSize};
}

sub check {
  my ($self) = @_;
  my $label = sprintf 'storage_%s_usage', $self->{sysExtStorageName};
  $label =~ s/\s+/_/g;
  $self->add_info(sprintf 'storage %s usage is %.2f%%',
      $self->{sysExtStorageName}, $self->{usage});
  $self->set_thresholds(metric => $label, warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => $label, value => $self->{usage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{usage},
      uom => '%',
  );
}

