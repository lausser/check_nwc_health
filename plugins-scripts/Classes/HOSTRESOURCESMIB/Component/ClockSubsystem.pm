package Classes::HOSTRESOURCESMIB::Component::ClockSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('HOST-RESOURCES-MIB', qw(
      hrSystemDate
  ));
  $self->{localSystemDate} = time;
}

sub check {
  my ($self) = @_;
  if ($self->{hrSystemDate}) {
    $self->add_info(sprintf "monitoring clock and device clock differ by %ds",
        $self->{hrSystemDate} - $self->{localSystemDate});
    $self->set_thresholds(metric => 'clock_deviation',
        warning => 60, critical => 120);
    $self->add_message($self->check_thresholds(metric => 'clock_deviation',
        value => abs($self->{hrSystemDate} - $self->{localSystemDate})));
    $self->add_perfdata(label => 'clock_deviation',
        value => $self->{hrSystemDate} - $self->{localSystemDate});
  }
}

