package CheckNwcHealth::Audiocodes::Component::AlarmSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AC-ALARM-MIB', [
    ['alarms', 'acActiveAlarmTable', 'CheckNwcHealth::Audiocodes::Component::AlarmSubsystem::Alarm'],
  ]);
}

 sub check {
   my ($self) = @_;
   $self->add_info('checking active alarms');
   if (scalar(@{$self->{alarms}}) == 0) {
     $self->add_info('no active alarms');
     $self->add_ok();
   } else {
     foreach (@{$self->{alarms}}) {
       $_->check();
     }
   }
 }

sub dump {
  my ($self) = @_;
  foreach (@{$self->{alarms}}) {
    $_->dump();
  }
}

package CheckNwcHealth::Audiocodes::Component::AlarmSubsystem::Alarm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $severity = $self->{acActiveAlarmSeverity};
  my $description = $self->{acActiveAlarmTextualDescription} || 'unknown alarm';
  $self->add_info(sprintf 'active alarm: %s (severity %s)', $description, $severity);
  if ($severity eq 'minor' || $severity eq 'major' || $severity eq 'critical') { # minor and above
    $self->add_critical(sprintf 'active alarm: %s', $description);
  } elsif ($severity eq 'warning') { # warning
    $self->add_warning(sprintf 'active alarm: %s', $description);
  } else {
    $self->add_ok();
  }
}

sub dump {
  my ($self) = @_;
  printf "alarm %d: %s (severity %d)\n",
      $self->{acActiveAlarmSequenceNumber}, $self->{acActiveAlarmTextualDescription}, $self->{acActiveAlarmSeverity};
}
