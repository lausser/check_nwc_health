package Classes::Nortel::S5::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('S5-CHASSIS-MIB', [
    ['comps', 's5ChasComTable', 'Classes::Nortel::S5::Component::EnvironmentalSubsystem::Comp' ],
  ]);
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{comps}}) {
    $_->check();
  }
  $self->reduce_messages("environmental hardware working fine");
}


package Classes::Nortel::S5::Component::EnvironmentalSubsystem::Comp;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{s5ChasComShortDescr} = $self->{s5ChasComDescr};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'component %s/%s status is %s (admin %s)',
      $self->{flat_indices}, $self->{s5ChasComShortDescr},
      $self->{s5ChasComOperState}, $self->{s5ChasComAdminState});
  if ($self->{s5ChasComOperState} eq 'removed') {
  } elsif ($self->{s5ChasComAdminState} eq 'disable') {
  } elsif (grep { $self->{s5ChasComOperState} eq $_ }
      (qw(normal resetInProg testing disabled))) {
    $self->add_ok();
  } elsif (grep { $self->{s5ChasComOperState} eq $_ }
      (qw(warning nonFatalErr))) {
    $self->add_warning();
  } elsif (grep { $self->{s5ChasComOperState} eq $_ }
      (qw(fatalErr))) {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
}
