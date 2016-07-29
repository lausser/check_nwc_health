package Classes::Cisco::CISCOFLASHMIB::Component::StorageSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-FLASH-MIB', [
      ['flash', 'ciscoFlashPartitionTable', 'Classes::Cisco::CISCOFLASHMIB::Component::StorageSubsystem::Flash'],
  ]);
}


package Classes::Cisco::CISCOFLASHMIB::Component::StorageSubsystem::Flash;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{free} = 100 * $self->{ciscoFlashPartitionFreeSpace} / $self->{ciscoFlashPartitionSize};
}

sub check {
  my $self = shift;
  my $label = sprintf 'storage_%s_free', $self->{ciscoFlashPartitionName};
  $label =~ s/\s+/_/g;
  $label =~ s/:/_/g;
  $self->add_info(sprintf 'storage %s has %.2f%% available, %.2fMB total',
      $self->{ciscoFlashPartitionName}, $self->{free},
      $self->{ciscoFlashPartitionSize} / 1024 / 1024);
  $self->set_thresholds(metric => $label, warning => "20:", critical => "10:");
  # this is useless for nagios regular output. use "-v" option if really needed
  #$self->add_message($self->check_thresholds(metric => $label, value => $self->{free}));
  $self->add_perfdata(
      label => $label,
      value => $self->{free},
      uom => '%',
  );
}
