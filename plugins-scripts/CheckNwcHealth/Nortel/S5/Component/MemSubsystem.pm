package CheckNwcHealth::Nortel::S5::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('S5-CHASSIS-MIB', [
    ['utils', 's5ChasUtilTable', 'CheckNwcHealth::Nortel::S5::Component::MemSubsystem::Mem' ],
  ]);
}


package CheckNwcHealth::Nortel::S5::Component::MemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{s5ChasUtilMemoryUsage} = 100 - 
      ($self->{s5ChasUtilMemoryAvailableMB} /
      $self->{s5ChasUtilMemoryTotalMB} * 100);
}

sub check {
  my ($self) = @_;
  my $label = sprintf 'memory_%s_usage', $self->{flat_indices};
  $self->add_info(sprintf 'memory %s usage is %.2f%%',
      $self->{flat_indices},,
      $self->{s5ChasUtilMemoryUsage});
  $self->set_thresholds(metric => $label, warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => $label, value => $self->{s5ChasUtilMemoryUsage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{s5ChasUtilMemoryUsage},
      uom => '%',
  );
}
# 3fach indexiert, als tabelle ausgeben und durchnumerieren
