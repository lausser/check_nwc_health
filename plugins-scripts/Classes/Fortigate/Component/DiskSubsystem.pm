package Classes::Fortigate::Component::DiskSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('FORTINET-FORTIGATE-MIB', (qw(
      fgSysDiskUsage fgSysDiskCapacity)));
  $self->{usage} = $self->{fgSysDiskCapacity} ? 
      100 * $self->{fgSysDiskUsage} /  $self->{fgSysDiskCapacity} : undef;
}

sub check {
  my $self = shift;
  $self->add_info('checking disks');
  if (! defined $self->{usage}) {
    $self->add_info(sprintf 'system has no disk');
    return;
  }
  $self->add_info(sprintf 'disk is %.2f%% full',
      $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}));
  $self->add_perfdata(
      label => 'disk_usage',
      value => $self->{usage},
      uom => '%',
  );
}

