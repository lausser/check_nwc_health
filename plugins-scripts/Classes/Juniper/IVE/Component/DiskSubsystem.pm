package Classes::Juniper::IVE::Component::DiskSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('JUNIPER-IVE-MIB', (qw(
      diskFullPercent)));
}

sub check {
  my $self = shift;
  $self->add_info('checking disks');
  $self->blacklist('di', '');
  $self->add_info(sprintf 'disk is %.2f%% full',
      $self->{diskFullPercent});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{diskFullPercent}));
  $self->add_perfdata(
      label => 'disk_usage',
      value => $self->{diskFullPercent},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

