package CheckNwcHealth::Audiocodes::Component::AlarmSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AC-ALARM-MIB', [
    ['alarms', 'acActiveAlarmTable', 'CheckNwcHealth::Audiocodes::Component::AlarmSubsystem::Alarm'],
  ]);
  # filter out DNS/NTP service alarms, those are handled by check-config mode
  # the check is on the alarm category (the leading title), not the whole text,
  # so an unrelated alarm that merely names a DNS/NTP host in its detail (e.g.
  # a certificate expiry citing a FQDN) is not misclassified and hidden.
  @{$self->{alarms}} = grep {
    _alarm_title($_->{acActiveAlarmTextualDescription}) !~ /^(?:DNS|NTP)\b/i
  } @{$self->{alarms}};
}

# leading alarm category/title, with the "[hostname] " and "Alarm cleared: "
# prefixes and everything after the first ": " or ". " removed
sub _alarm_title {
  my ($desc) = @_;
  return '' unless defined $desc;
  (my $title = $desc) =~ s/^\[[^\]]*\]\s*//;
  $title =~ s/^Alarm cleared:\s*//i;
  $title =~ s/^(.*?)[:.]\s.*$/$1/s;
  return $title;
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
  if ($severity eq 'major' || $severity eq 'critical') { # major and above
    $self->add_critical(sprintf 'active alarm: %s', $description);
  } elsif ($severity eq 'minor' || $severity eq 'warning') { # minor and warning
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
