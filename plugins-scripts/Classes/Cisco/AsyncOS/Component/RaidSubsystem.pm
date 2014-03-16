package Classes::Cisco::AsyncOS::Component::RaidSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('ASYNCOS-MAIL-MIB', (qw(
      raidEvents)));
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['raids', 'raidTable', 'Classes::Cisco::AsyncOS::Component::RaidSubsystem::Raid'],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking raids');
  $self->blacklist('r', '');
  foreach (@{$self->{raids}}) {
    $_->check();
  }
}


package Classes::Cisco::AsyncOS::Component::RaidSubsystem::Raid;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('r', $self->{raidIndex});
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

