package CheckNwcHealth::Lantronix::SLS;
our @ISA = qw(CheckNwcHealth::Lantronix);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Lantronix::SLS::Component::EnvironmentalSubsystem");
  } else {
    $self->no_such_mode();
  }
}


package CheckNwcHealth::Lantronix::SLS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('LARA-MIB', qw(checkHostPower));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'host power status is %s', $self->{checkHostPower});
  if ($self->{checkHostPower} eq 'hasPower') {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
}

