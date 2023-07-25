package CheckNwcHealth::Cisco::AsyncOS::Component::RaidSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ASYNCOS-MAIL-MIB', (qw(
      raidEvents)));
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['raids', 'raidTable', 'CheckNwcHealth::Cisco::AsyncOS::Component::RaidSubsystem::Raid'],
  ]);
}

package CheckNwcHealth::Cisco::AsyncOS::Component::RaidSubsystem::Raid;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'raid %d has status %s',
      $self->{raidIndex},
      $self->{raidStatus});
  if ($self->{raidStatus} eq 'driveHealthy') {
  } elsif ($self->{raidStatus} eq 'driveRebuild') {
    $self->add_warning();
  } elsif ($self->{raidStatus} eq 'driveFailure') {
    $self->add_critical();
  }
}

