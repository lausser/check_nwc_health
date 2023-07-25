package CheckNwcHealth::CheckPoint::Firewall1::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['powersupplies', 'powerSupplyTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

package CheckNwcHealth::CheckPoint::Firewall1::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  #Ignore Dummy values
  if ($self->{powerSupplyStatus} ne 'Dummy') {
    $self->add_info(sprintf 'power supply %d status is %s', 
        $self->{powerSupplyIndex},
        $self->{powerSupplyStatus});
    if ($self->{powerSupplyStatus} eq 'Up') {
      $self->add_ok();
    } elsif ($self->{powerSupplyStatus} eq 'Down') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
  }
}
