package CheckNwcHealth::PulseSecure::Gateway::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('PULSESECURE-PSG-MIB', (qw(
      diskFullPercent raidDescription logFullPercent)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking disks');
  $self->add_info(sprintf 'disk is %.2f%% full',
      $self->{diskFullPercent});
  $self->set_thresholds(metric => 'disk_usage', warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(metric => 'disk_usage',
      value => $self->{diskFullPercent}));
  $self->add_perfdata(
      label => 'disk_usage',
      value => $self->{diskFullPercent},
      uom => '%',
  );
  if ($self->{raidDescription} && $self->{raidDescription} =~ /(failed)|(unknown)/) {
    $self->add_critical($self->{raidDescription});
  }
  if (defined $self->{logFullPercent}) {
    $self->add_info(sprintf 'log is %.2f%% full',
        $self->{logFullPercent});
    $self->set_thresholds(metric => 'log_usage', warning => 80, critical => 90);
    $self->add_message($self->check_thresholds(metric => 'log_usage',
        value => $self->{logFullPercent}));
    $self->add_perfdata(
        label => 'log_usage',
        value => $self->{logFullPercent},
        uom => '%',
    );
  }
}

