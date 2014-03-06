package Classes::F5::F5BIGIP::Component::PowersupplySubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['powersupplies', 'sysChassisPowerSupplyTable', 'Classes::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking powersupplies');
  $self->blacklist('pp', '');
  foreach (@{$self->{powersupplies}}) {
    $_->check();
  }
}


package Classes::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('p', $self->{sysChassisPowerSupplyIndex});
  $self->add_info(sprintf 'chassis powersupply %d is %s',
      $self->{sysChassisPowerSupplyIndex},
      $self->{sysChassisPowerSupplyStatus});
  if ($self->{sysChassisPowerSupplyStatus} eq 'notpresent') {
  } else {
    if ($self->{sysChassisPowerSupplyStatus} ne 'good') {
      $self->add_critical();
    }
  }
}

