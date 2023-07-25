package CheckNwcHealth::Eltex::MES::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ELTEX-MIB', (qw(eltexStackUnitsNumber)));
}

# Specify threshold values, so that you understand when the number of units
# decreases, for example we have only 2 units in stack, so we should get
# warning state if one of unit goes down:
# ./check_nwc_health --hostname 10.10.10.2 --mode ha-status --warning 2:
# OK - stack have 2 units | 'units'=2;2:;0:;;
# and when only one unit left:
# WARNING - stack have 1 units | 'units'=1;2:;0:;;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'stack have %s units',
    $self->{eltexStackUnitsNumber});
  $self->set_thresholds(warning => '0:', critical => '0:');
  $self->add_message($self->check_thresholds(
    $self->{eltexStackUnitsNumber}));
  $self->add_perfdata(
    label => 'units',
    value => $self->{eltexStackUnitsNumber},
  );
}
