package Classes::Cisco::AsyncOS::Component::FanSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['fans', 'fanTable', 'Classes::Cisco::AsyncOS::Component::FanSubsystem::Fan'],
  ]);
}

package Classes::Cisco::AsyncOS::Component::FanSubsystem::Fan;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'fan %d (%s) has %s rpm',
      $self->{fanIndex},
      $self->{fanName},
      $self->{fanRPMs});
  $self->add_perfdata(
      label => sprintf('fan_c%s', $self->{fanIndex}),
      value => $self->{fanRPMs},
      thresholds => 0,
  );
}

