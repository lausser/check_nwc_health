package Classes::Cisco::AsyncOS::Component::MemSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('ASYNCOS-MAIL-MIB', (qw(
      perCentMemoryUtilization memoryAvailabilityStatus)));
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%% (%s)',
      $self->{perCentMemoryUtilization}, $self->{memoryAvailabilityStatus});
  $self->set_thresholds(warning => 80, critical => 90);
  if ($self->check_thresholds($self->{perCentMemoryUtilization})) {
    $self->add_message($self->check_thresholds($self->{perCentMemoryUtilization}));
  } elsif ($self->{memoryAvailabilityStatus} eq 'memoryShortage') {
    $self->add_warning();
    $self->set_thresholds(warning => $self->{perCentMemoryUtilization}, critical => 90);
  } elsif ($self->{memoryAvailabilityStatus} eq 'memoryFull') {
    $self->add_critical();
    $self->set_thresholds(warning => 80, critical => $self->{perCentMemoryUtilization});
  } else {
    $self->add_ok();
  }
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{perCentMemoryUtilization},
      uom => '%',
  );
}

