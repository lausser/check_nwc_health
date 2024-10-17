package CheckNwcHealth::F5::Velos::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-PLATFORM-STATS-MIB', [
      ['processorstats', 'cpuProcessorStatsTable', 'Monitoring::GLPlugin::SNMP::TableItem', undef, ["index"]],
      ['temperatures', 'temperatureStatsTable', 'CheckNwcHealth::F5::Velos::Component::TemperatureSubsystem::Temperature'],
  ]);
  $self->merge_tables_with_code('temperatures', 'processorstats', sub {
      # siehe CpuSubsystem
      my ($temp, $proc) = @_;
      return ($proc->{flat_indices} eq $temp->{flat_indices}.".1") ? 1 : 0;
  });
}

package CheckNwcHealth::F5::Velos::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s temperature is %.2f',
      $self->{index}, $self->{tempCurrent});
  my $label = sprintf "temp_%s", $self->{index};
  $self->set_thresholds(
      metric => $label,
      warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(metric => $label, value => $self->{tempCurrent}));
  $self->add_perfdata(
      label => $label,
      value => $self->{tempCurrent},
  );
}

