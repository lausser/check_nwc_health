package CheckNwcHealth::F5::Velos::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-PLATFORM-STATS-MIB', [
      ['processorstats', 'cpuProcessorStatsTable', 'Monitoring::GLPlugin::SNMP::TableItem', undef, ["index"]],
      ['fans', 'fantrayStatsTable', 'CheckNwcHealth::F5::Velos::Component::FanSubsystem::Fan'],
  ]);
}

package CheckNwcHealth::F5::Velos::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  foreach (1..12) {
    next if ! exists $self->{"fan-".$_."-speed"};
    my $label = sprintf "fan_%s_%d_rpm", $self->{index}, $_;
    $self->add_perfdata(
        label => $label,
        value => $self->{"fan-".$_."-speed"},
    );
  }
}

