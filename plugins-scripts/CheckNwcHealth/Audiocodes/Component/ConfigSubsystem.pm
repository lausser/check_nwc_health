package CheckNwcHealth::Audiocodes::Component::ConfigSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AC-ALARM-MIB', [
    ['alarms', 'acActiveAlarmTable', 'CheckNwcHealth::Audiocodes::Component::ConfigSubsystem::Alarm'],
  ]);
  # filter for DNS and NTP related alarms only
  @{$self->{dns_alarms}} = grep {
    $_->{acActiveAlarmTextualDescription} =~ /DNS/i
  } @{$self->{alarms}};
  @{$self->{ntp_alarms}} = grep {
    $_->{acActiveAlarmTextualDescription} =~ /NTP/i
  } @{$self->{alarms}};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking DNS/NTP service alarms');
  my $dns_count = scalar(@{$self->{dns_alarms}});
  my $ntp_count = scalar(@{$self->{ntp_alarms}});
  if ($dns_count == 0 && $ntp_count == 0) {
    $self->add_info('no active DNS or NTP alarms');
    $self->add_ok('no active DNS or NTP alarms');
  } else {
    foreach (@{$self->{dns_alarms}}) {
      $_->check();
    }
    foreach (@{$self->{ntp_alarms}}) {
      $_->check();
    }
  }
}


package CheckNwcHealth::Audiocodes::Component::ConfigSubsystem::Alarm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $severity = $self->{acActiveAlarmSeverity};
  my $description = $self->{acActiveAlarmTextualDescription} || 'unknown alarm';
  $self->add_info(sprintf 'active alarm: %s (severity %s)', $description, $severity);
  if ($severity eq 'minor' || $severity eq 'major' || $severity eq 'critical') {
    $self->add_critical(sprintf 'active alarm: %s', $description);
  } elsif ($severity eq 'warning') {
    $self->add_warning(sprintf 'active alarm: %s', $description);
  } else {
    $self->add_ok();
  }
}

