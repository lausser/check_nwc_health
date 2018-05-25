package Classes::Juniper::SRX::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['leds', 'jnxLEDTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Led'],
    ['operatins', 'jnxOperatingTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Operating'],
    ['containers', 'jnxContainersTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Container'],
    ['fru', 'jnxFruTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fru'],
    ['redun', 'jnxRedundancyTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Redundancy'],
    ['contents', 'jnxContentsTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Content'],
    ['filled', 'jnxFilledTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fille'],
  ]);
  $self->merge_tables("operatins", "filled", "fru", "contents");
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Led;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'led %s is %s', $self->{jnxLEDDescr},
      $self->{jnxLEDState});
  if ($self->{jnxLEDState} eq 'yellow') {
    $self->add_warning();
  } elsif ($self->{jnxLEDState} eq 'red') {
    $self->add_critical();
  } elsif ($self->{jnxLEDState} eq 'amber') {
    $self->add_critical();
  } elsif ($self->{jnxLEDState} eq 'green') {
    $self->add_ok();
  }
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Container;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fru;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Redundancy;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Content;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fille;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);



package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Operating;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  if ($self->{jnxOperatingDescr} =~ /Routing Engine$/) {
    bless $self, "Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Engine";
  }
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Engine;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s temperature is %.2f',
      $self->{jnxOperatingDescr}, $self->{jnxOperatingTemp});
  my $label = 'temp_'.$self->{jnxOperatingDescr};
  $self->set_thresholds(metric => $label, warning => 50, critical => 60);
  $self->add_message($self->check_thresholds(metric => $label, 
      value => $self->{jnxOperatingTemp}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxOperatingTemp},
  );
}

