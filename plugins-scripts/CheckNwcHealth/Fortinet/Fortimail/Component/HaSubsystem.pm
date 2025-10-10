package CheckNwcHealth::Fortinet::Fortimail::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('FORTINET-FORTIMAIL-MIB', (qw(
      fmlHAMode fmlHAEffectiveMode
      fmlHAEventId fmlHAUnitIp fmlHAEventReason
  )));
}

sub check {
  my ($self) = @_;
  $self->add_info("ha mode is $self->{fmlHAMode}, effective mode is $self->{fmlHAEffectiveMode}");
  if ($self->{fmlHAMode} eq 'off') {
    $self->add_ok("ha is off");
  } elsif ($self->{fmlHAMode} eq $self->{fmlHAEffectiveMode}) {
    $self->add_ok("ha status is ok");
  } else {
    $self->add_critical("ha status is not effective");
  }

  if (defined $self->{fmlHAEventId}) {
    $self->add_warning("HA event: $self->{fmlHAEventId} on $self->{fmlHAUnitIp} ($self->{fmlHAEventReason})");
  }
}