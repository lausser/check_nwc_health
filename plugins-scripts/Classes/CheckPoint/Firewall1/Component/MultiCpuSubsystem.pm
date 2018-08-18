package Classes::CheckPoint::Firewall1::Component::MultiCpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['cpus', 'multiProcTable', 'Classes::CheckPoint::Firewall1::Component::MultiCpuSubsystem::CPU'],
  ]);
}

sub check {
  my $self = shift;
  foreach (sort {$a->{multiProcIndex} <=> $b->{multiProcIndex}} @{$self->{cpus}}) {
    $_->check();
  }
  if ($self->opts->report eq "short") {
    $self->clear_ok();
    $self->add_ok('no problems') if ! $self->check_messages();
  }
}

package Classes::CheckPoint::Firewall1::Component::MultiCpuSubsystem::CPU;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cpu%s usage is %.2f%%',
      $self->{multiProcIndex},
      $self->{multiProcUsage});
  $self->set_thresholds(metric => "cpu".$self->{multiProcIndex}."_usage", warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(metric => "cpu".$self->{multiProcIndex}."_usage", value => $self->{multiProcUsage}));
  $self->add_perfdata(
      label => "cpu".$self->{multiProcIndex}."_usage",
      value => $self->{multiProcUsage},
      uom => '%',
  );
}
