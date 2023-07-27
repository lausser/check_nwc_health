package CheckNwcHealth::PulseSecure::Gateway::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('PULSESECURE-PSG-MIB', (qw(
      iveMemoryUtil iveSwapUtil)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%, swap usage is %.2f%%',
      $self->{iveMemoryUtil}, $self->{iveSwapUtil});
  $self->set_thresholds(warning => 90, critical => 95);
  $self->add_message($self->check_thresholds($self->{iveMemoryUtil}),
      sprintf 'memory usage is %.2f%%', $self->{iveMemoryUtil});
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{iveMemoryUtil},
      uom => '%',
  );
  $self->set_thresholds(warning => 5, critical => 10);
  $self->add_message($self->check_thresholds($self->{iveSwapUtil}),
      sprintf 'swap usage is %.2f%%', $self->{iveSwapUtil});
  $self->add_perfdata(
      label => 'swap_usage',
      value => $self->{iveSwapUtil},
      uom => '%',
  );
}

