package CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::ModuleSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-ENTITY-FRU-CONTROL-MIB', [
    ['modules', 'cefcModuleTable', 'CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::ModuleSubsystem::Module', undef, ["cefcModuleAdminStatus", "cefcModuleOperStatus"]],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'CheckNwcHealth::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::PhysicalEntity', undef, ["entPhysicalIndex", "entPhysicalDescr", "entPhysicalClass"]],
  ]);
  @{$self->{entities}} = grep { $_->{entPhysicalClass} eq 'module' } @{$self->{entities}};
  foreach my $module (@{$self->{modules}}) {
    foreach my $entity (@{$self->{entities}}) {
      if ($module->{flat_indices} eq $entity->{entPhysicalIndex}) {
        $module->{entity} = $entity;
      }
    }
  }
}

package CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::ModuleSubsystem::Module;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my @criticals = qw(failed missing okButPowerOverCritical powerDenied);
  my @warnings = qw(mismatchWithParent mismatchConfig diagFailed
    outOfServiceAdmin outOfServiceEnvTemp powerDown okButPowerOverWarning
    okButAuthFailed);
  $self->add_info(sprintf 'module %s%s admin status is %s, oper status is %s',
      $self->{flat_indices},
      #exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.' idx '.$self->{entity}->{entPhysicalIndex}.' class '.$self->{entity}->{entPhysicalClass}.')' : '',
      exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.')' : '',
      $self->{cefcModuleAdminStatus},
      $self->{cefcModuleOperStatus});
  if ($self->{cefcModuleAdminStatus} ne 'enabled' && defined $self->opts->mitigation() && $self->opts->mitigation() == 0) {
    $self->add_ok();
  } if ($self->{cefcModuleOperStatus} eq "unknown") {
    $self->add_unknown();
  } elsif (grep $_ eq $self->{cefcModuleOperStatus}, @criticals) {
    $self->add_critical();
  } elsif (grep $_ eq $self->{cefcModuleOperStatus}, @warnings) {
    $self->add_warning();
  }
  # else ok
}

__END__
Operational module states.  Valid values are :
==============================================

unknown(1)           Module is not in one of other states

normal operational states:
--------------------------

ok(2)                 Module is operational.

disabled(3)           Module is administratively disabled.

okButDiagFailed(4)    Module is operational but there is some
                      diagnostic information available.

transitional states:
--------------------

boot(5)               Module is currently in the process of
                      bringing up image.  After boot, it starts
                      its operational software and transitions
                      to the appropriate state.

selfTest(6)           Module is performing selfTest.


failure states:
---------------

failed(7)              Module has failed due to some condition
                       not stated above.

missing(8)             Module has been provisioned, but it is
                       missing

mismatchWithParent(9)  Module is not compatible with parent
                       entity. Module has not been provisioned
                       and wrong type of module is plugged in.
                       This state can be cleared by plugging
                       in the appropriate module.

mismatchConfig(10)     Module is not compatible with the current
                       configuration. Module was correctly
                       provisioned earlier, however the module
                       was replaced by an incompatible module.
                       This state can be resolved by clearing
                       the configuration, or replacing with the
                       appropriate module.

diagFailed(11)         Module diagnostic test failed due to some
                       hardware failure.

dormant(12)            Module is waiting for an external or
                       internal event to become operational.

outOfServiceAdmin(13)  module is administratively set to be
                       powered on but out of service.

outOfServiceEnvTemp(14)Module is powered on but out of service,
                       due to environmental temperature problem.
                       An out-o-service module consumes less
                       power thus will cool down the board.

poweredDown(15)        Module is in powered down state.

poweredUp(16)          Module is in powered up state.

powerDenied(17)        System does not have enough power in
                       power budget to power on this module.

powerCycled(18)        Module is being power cycled.

okButPowerOverWarning(19) Module is drawing more power than
                       allocated to this module. The module
                       is still operational but may go into
                       a failure state. This state may be
                       caused by misconfiguration of power
                       requirements (especially for inline
                       power).

okButPowerOverCritical(20) Module is drawing more power
                       than this module is designed to
                       handle. The module is still
                       operational but may go into a
                       failure state and could potentially
                       take the system down. This state
                       may be caused by gross misconfi-
                       guration of power requirements
                       (especially for inline power).

syncInProgress(21)     Synchronization in progress.
                       In a high availability system there
                       will be 2 control modules, active and
                       standby.
                       This transitional state specifies the
                       synchronization of data between the
                       active and standby modules.

upgrading(22)          Module is upgrading.

okButAuthFailed(23)    Module is operational but did not pass
                       hardware integrity verification.
