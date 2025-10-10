package CheckNwcHealth::Fortinet::Fortimail::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('FORTINET-FORTIMAIL-MIB', (qw(
      fmlSysLogDiskUsage fmlSysMailDiskUsage)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking disks');
  $self->set_thresholds(warning => 80, critical => 90);
  if (defined $self->{fmlSysLogDiskUsage}) {
    $self->add_info(sprintf 'log disk is %.2f%% full',
        $self->{fmlSysLogDiskUsage});
    $self->add_message($self->check_thresholds($self->{fmlSysLogDiskUsage}));
    $self->add_perfdata(
        label => 'log_disk_usage',
        value => $self->{fmlSysLogDiskUsage},
        uom => '%',
    );
  }
  if (defined $self->{fmlSysMailDiskUsage}) {
    $self->add_info(sprintf 'mail disk is %.2f%% full',
        $self->{fmlSysMailDiskUsage});
    $self->add_message($self->check_thresholds($self->{fmlSysMailDiskUsage}));
    $self->add_perfdata(
        label => 'mail_disk_usage',
        value => $self->{fmlSysMailDiskUsage},
        uom => '%',
    );
  }
}

