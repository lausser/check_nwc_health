package CheckNwcHealth::Bluecat::AddressManager::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('BAM-SNMP-MIB', (qw(
        freeMemory maxMemory usageThresholdExceeded
  )));
  $self->{jvm_usage} = 100 - 100 * $self->{freeMemory} / $self->{maxMemory};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'jvm mem usage is %.2f%%',
      $self->{jvm_usage});
  $self->set_thresholds(metric => "jvm_memory_usage",
      warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => "jvm_memory_usage",
      value => $self->{jvm_usage}));
  $self->add_perfdata(
      label => 'jvm_memory_usage',
      value => $self->{jvm_usage},
      uom => '%',
  );
}


