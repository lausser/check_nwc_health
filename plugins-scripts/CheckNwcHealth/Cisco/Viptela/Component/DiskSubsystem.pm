package CheckNwcHealth::Cisco::Viptela::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('VIPTELA-OPER-SYSTEM', (qw(
      systemStatusDiskUse systemStatusDiskStatus
  )));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking disks');
  $self->add_info(sprintf 'disk is %.2f%% full',
      $self->{systemStatusDiskUse});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{systemStatusDiskUse}));
  $self->add_perfdata(
      label => 'disk_usage',
      value => $self->{systemStatusDiskUse},
      uom => '%',
  );
}

