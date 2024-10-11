package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalMemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-UNIFIED-COMPUTING-MEMORY-MIB', [
      ['memorys', 'cucsMemoryUnitTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalMemSubsystem::Mem'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  $self->subsystem_summary(sprintf("%d dimms checked", scalar(@{$self->{memorys}})));
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalMemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsMemoryUnitPresence} eq "missing") {
    return;
  }
  $self->add_info(sprintf "%s is %s",
      $self->{cucsMemoryUnitDn},
      $self->{cucsMemoryUnitOperState}
  );
  if ($self->{cucsMemoryUnitOperState} ne "operable") {
    $self->add_warning();
  } else {
    $self->add_ok();
  }
}


