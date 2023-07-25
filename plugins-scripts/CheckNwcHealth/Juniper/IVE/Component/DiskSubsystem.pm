package CheckNwcHealth::Juniper::IVE::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('JUNIPER-IVE-MIB', (qw(
      diskFullPercent)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking disks');
  $self->add_info(sprintf 'disk is %.2f%% full',
      $self->{diskFullPercent});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{diskFullPercent}));
  $self->add_perfdata(
      label => 'disk_usage',
      value => $self->{diskFullPercent},
      uom => '%',
  );
}

