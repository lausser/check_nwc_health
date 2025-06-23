package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalRackUnitSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-UNIFIED-COMPUTING-COMPUTE-MIB', [
      ['rackunits', 'cucsComputeRackUnitTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalRackUnitSubsystem::RackUnit'],
      ['rackunittemps', 'cucsComputeRackUnitMbTempStatsTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalRackUnitSubsystem::RackUnitTempStat'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  $self->subsystem_summary(
      sprintf("%d rack units checked", scalar(@{$self->{rackunits}}))
  );
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalRackUnitSubsystem::RackUnit;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "rack unit %s is %s and %s",
      $self->{cucsComputeRackUnitName},
      $self->{cucsComputeRackUnitOperability},
      $self->{cucsComputeRackUnitOperState}
  );
  if ($self->{cucsComputeRackUnitOperState} eq "ok") {
    $self->add_ok();
  } else {
    $self->add_warning();
  }
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalRackUnitSubsystem::RackUnitTempStat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  foreach my $temp (qw(Ambient Front Ioh1 Ioh2 Rear)) {
    my $label = "temp_".(lc $temp)."_".(lc $self->{cucsComputeRackUnitMbTempStatsDn});
    if ($self->{"cucsComputeRackUnitMbTempStats".$temp."Temp"}) {
      $self->add_perfdata(
        label => $label,
        value => $self->{"cucsComputeRackUnitMbTempStats".$temp."Temp"},
      );
    }
  }
}


