package CheckNwcHealth::Audiocodes::Component::ConfigSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('AC-ALARM-MIB', [
    ['alarms', 'acActiveAlarmTable', 'CheckNwcHealth::Audiocodes::Component::ConfigSubsystem::Alarm'],
  ]);
  # filter for DNS and NTP service alarms only. The check is on the alarm
  # category (the leading title), not the whole text, so an unrelated alarm
  # that merely names a DNS/NTP host in its detail (e.g. a certificate expiry
  # citing a FQDN) is not picked up here.
  @{$self->{dns_alarms}} = grep {
    _alarm_title($_->{acActiveAlarmTextualDescription}) =~ /^DNS\b/i
  } @{$self->{alarms}};
  @{$self->{ntp_alarms}} = grep {
    _alarm_title($_->{acActiveAlarmTextualDescription}) =~ /^NTP\b/i
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
  if ($severity eq 'major' || $severity eq 'critical') {
    $self->add_critical(sprintf 'active alarm: %s', $description);
  } elsif ($severity eq 'minor' || $severity eq 'warning') {
    # DNS/NTP alarms are advisory upstream-dependency problems: the SBC keeps
    # working for a while without them. Use add_warning_mitigation so the user
    # can reduce the level with --mitigation (e.g. --mitigation ok) if they
    # consider a DNS/NTP blip acceptable.
    $self->add_warning_mitigation(sprintf 'active alarm: %s', $description);
  } else {
    $self->add_ok();
  }
}

