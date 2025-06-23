package CheckNwcHealth::Cisco::CISCOENTITYQFPMIB::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-ENTITY-QFP-MIB', [
      #['cpus', 'ceqfpUtilizationTable', 'CheckNwcHealth::Cisco::CISCOENTITYQFPMIB::Component::CpuSubsystem::Cpu', undef, ["ceqfpUtilProcessingLoad"] ],
      ['cpus', 'ceqfpUtilizationTable', 'CheckNwcHealth::Cisco::CISCOENTITYQFPMIB::Component::CpuSubsystem::Cpu', sub { my $o = shift; $o->{ceqfpUtilTimeInterval} eq "fiveMinutes"; }, ["ceqfpUtilTimeInterval", "ceqfpUtilProcessingLoad"]],
  ]);
}


package CheckNwcHealth::Cisco::CISCOENTITYQFPMIB::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  # fiveSeconds(1), oneMinute(2), fiveMinutes(3), sixtyMinutes(4)
  $self->{ceqfpUtilTimeInterval} = $self->mibs_and_oids_definition(
      'CISCO-ENTITY-QFP-MIB', 'CiscoQfpTimeInterval', $self->{indices}->[1]);
  $self->{entPhysicalName} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalName', $self->{indices}->[0]);
  $self->{name} = $self->{entPhysicalName};
  $self->{usage} = $self->{ceqfpUtilProcessingLoad};
}

sub check {
  my ($self) = @_;
  $self->{label} = $self->{name};
  $self->add_info(sprintf 'cpu %s usage (5 min avg.) is %.2f%%',
      $self->{name}, $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{label}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

