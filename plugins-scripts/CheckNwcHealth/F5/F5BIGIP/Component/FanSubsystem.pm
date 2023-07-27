package CheckNwcHealth::F5::F5BIGIP::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['fans', 'sysChassisFanTable', 'CheckNwcHealth::F5::F5BIGIP::Component::FanSubsystem::Fan'],
  ]);
}

package CheckNwcHealth::F5::F5BIGIP::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'chassis fan %d is %s (%drpm)',
      $self->{sysChassisFanIndex},
      $self->{sysChassisFanStatus},
      $self->{sysChassisFanSpeed});
  if ($self->{sysChassisFanStatus} eq 'notpresent') {
  } else {
    if ($self->{sysChassisFanStatus} ne 'good') {
      $self->add_critical();
    }
    $self->add_perfdata(
        label => sprintf('fan_%s', $self->{sysChassisFanIndex}),
        value => $self->{sysChassisFanSpeed},
    );
  }
}

