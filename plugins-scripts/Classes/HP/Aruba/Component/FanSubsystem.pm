package Classes::HP::Aruba::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ARUBAWIRED-FAN-MIB', [
      ['fans', 'arubaWiredFanTable', 'Classes::HP::Aruba::Component::FanSubsystem::Fan'],
  ]);
}

package Classes::HP::Aruba::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'fan %s/%s status is %s', 
      $self->{flat_indices},
      $self->{arubaWiredFanName},
      $self->{arubaWiredFanState});
  if ($self->{arubaWiredFanState} eq 'ok') {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  my $label = sprintf "fan_%s_rpm", $self->{flat_indices};
  $self->add_perfdata(label => $label,
      value => $self->{arubaWiredFanRPM},
  );
}
