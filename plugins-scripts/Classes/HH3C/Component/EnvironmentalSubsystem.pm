package Classes::HH3C::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::HH3C::Component::EntitySubsystem);
use strict;

sub init {
  my $self = shift;

  $self->get_entities('Classes::HH3C::Component::EnvironmentalSubsystem::EntityState');

  my $i = 0;
  foreach my $h ($self->get_sub_table('HH3C-ENTITY-EXT-MIB', [ 'hh3cEntityExtErrorStatus' ])) {
    foreach (keys %$h) {
      next if $_ =~ /indices/;
      @{$self->{entities}}[$i]->{$_} = $h->{$_};
    }
    $i++;
  }
}

sub check {
  my $self = shift;

  $self->add_info('checking entities');
  if (scalar (@{$self->{entities}}) == 0) {
    $self->add_unknown('no entities found');
  } else {
    foreach (@{$self->{entities}}) {
      $_->check();
    }
    if (! $self->check_messages()) {
      $self->add_ok("environmental hardware working fine");
    }
  }
}

package Classes::HH3C::Component::EnvironmentalSubsystem::EntityState;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s (%s) is %s',
      $self->{entPhysicalDescr},
      $self->{entPhysicalClass},
      $self->{hh3cEntityExtErrorStatus});

  if ($self->{hh3cEntityExtErrorStatus} eq "normal") {
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
