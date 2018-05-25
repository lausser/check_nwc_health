package Classes::HH3C::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::HH3C::Component::EntitySubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables("ENTITY-MIB", [
    ["entities", "entPhysicalTable", "Classes::HH3C::Component::EnvironmentalSubsystem::Entity", undef, ["entPhysicalDescr", "entPhysicalName", "entPhysicalClass"]]
  ]);
  $self->get_snmp_tables("HH3C-ENTITY-EXT-MIB", [
    ["entitystates", "hh3cEntityExtStateTable", "Classes::HH3C::Component::EnvironmentalSubsystem::EntityState", undef, ["hh3cEntityExtErrorStatus"]]
  ]);
  $self->merge_tables("entities", "entitystates");
}

sub check {
  my ($self) = @_;
  $self->add_info('checking entities');
  if (scalar (@{$self->{entities}}) == 0) {
    $self->add_unknown('no entities found');
  } else {
    foreach (@{$self->{entities}}) {
      $_->check();
    }
    if (! $self->check_messages()) {
      $self->reduce_messages_short("environmental hardware working fine");
    }
  }
}

package Classes::HH3C::Component::EnvironmentalSubsystem::EntityState;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::HH3C::Component::EnvironmentalSubsystem::Entity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s (%s) is %s',
      $self->{entPhysicalName} || $self->{entPhysicalDescr},
      $self->{entPhysicalClass},
      $self->{hh3cEntityExtErrorStatus});

  if ($self->{hh3cEntityExtErrorStatus} eq "notSupported") {
    # no health check implemented for this entity
    $self->add_ok();
  } elsif ($self->{hh3cEntityExtErrorStatus} eq "normal") {
    $self->add_ok();
  } elsif (
    $self->{hh3cEntityExtErrorStatus} eq "entityAbsent" or
    $self->{hh3cEntityExtErrorStatus} =~ /^sfp/
  ) {
    $self->add_warning();
  } else {
    $self->add_critical();
  }
}

