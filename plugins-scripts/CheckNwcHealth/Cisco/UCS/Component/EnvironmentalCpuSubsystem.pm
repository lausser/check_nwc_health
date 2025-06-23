package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalCpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-UNIFIED-COMPUTING-PROCESSOR-MIB', [
      ['cpuenvstats', 'cucsProcessorEnvStatsTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalCpuSubsystem::CpuEnvStat'],
      ['processorunits', 'cucsProcessorUnitTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalCpuSubsystem::ProcessorUnit'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  $self->subsystem_summary(sprintf("%d cpus checked", scalar(@{$self->{processorunits}})));
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalCpuSubsystem::CpuEnvStat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s temperature is %.2fC",
      $self->{cucsProcessorEnvStatsDn},
      $self->{cucsProcessorEnvStatsTemperature}
  );
  $self->add_ok();
  my $label = "temp_".$self->{cucsProcessorEnvStatsDn};
  $self->add_perfdata(
      label => $label,
      value => $self->{cucsProcessorEnvStatsTemperature},
  );
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalCpuSubsystem::ProcessorUnit;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsProcessorUnitPresence} eq "equipped") {
    $self->add_info(sprintf "cpu %s is %s",
        $self->{cucsProcessorUnitRn},
        $self->{cucsProcessorUnitOperability}
    );
    if ($self->{cucsProcessorUnitOperability} ne "operable") {
      $self->add_warning();
    } else {
      $self->add_ok();
    }
  }
}


