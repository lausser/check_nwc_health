package CheckNwcHealth::Cisco::AsyncOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ASYNCOS-MAIL-MIB', (qw(
      perCentMemoryUtilization memoryAvailabilityStatus)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{perCentMemoryUtilization});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{perCentMemoryUtilization}));
  if ($self->{memoryAvailabilityStatus}) {
    $self->add_info(sprintf "memoryAvailabilityStatus is %s",
        $self->{memoryAvailabilityStatus});
    if ($self->{memoryAvailabilityStatus} eq 'memoryShortage') {
      $self->add_warning();
      $self->set_thresholds(warning => $self->{perCentMemoryUtilization}, critical => 90);
    } elsif ($self->{memoryAvailabilityStatus} eq 'memoryFull') {
      $self->add_critical();
      $self->set_thresholds(warning => 80, critical => $self->{perCentMemoryUtilization});
    } else {
      $self->add_ok();
    }
  }
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{perCentMemoryUtilization},
      uom => '%',
  );
}

