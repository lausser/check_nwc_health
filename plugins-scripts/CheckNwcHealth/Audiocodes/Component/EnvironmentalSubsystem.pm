package CheckNwcHealth::Audiocodes::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

  sub init {
   my ($self) = @_;
    $self->get_snmp_objects('AC-SYSTEM-MIB', (qw(acSysStateGWSeverity)));
    $self->init_subsystems([
        ["temperature_subsystem", "CheckNwcHealth::Audiocodes::Component::TemperatureSubsystem"],
        ["fan_subsystem", "CheckNwcHealth::Audiocodes::Component::FanSubsystem"],
        ["powersupply_subsystem", "CheckNwcHealth::Audiocodes::Component::PowersupplySubsystem"],
        ["disk_subsystem", "CheckNwcHealth::Audiocodes::Component::DiskSubsystem"],
        ["fru_subsystem", "CheckNwcHealth::Audiocodes::Component::FruSubsystem"],
        ["alarm_subsystem", "CheckNwcHealth::Audiocodes::Component::AlarmSubsystem"],
    ]);
 }

sub check {
  my ($self) = @_;
  if (defined $self->{acSysStateGWSeverity}) {
    my $severity = $self->{acSysStateGWSeverity};
    if ($severity eq 'noAlarm' || $severity eq 'cleared') {
      $self->add_info('gateway severity is noAlarm');
    } elsif ($severity eq 'indeterminate' || $severity eq 'warning') {
      $self->add_warning(sprintf 'gateway severity is %s', $severity);
    } elsif ($severity eq 'minor' || $severity eq 'major' || $severity eq 'critical') {
      $self->add_critical(sprintf 'gateway severity is %s', $severity);
    }
  }
  $self->check_subsystems();
  $self->reduce_messages_short("environmental hardware working fine")
      if ! $self->opts->subsystem;
}

sub dump {
  my ($self) = @_;
  $self->dump_subsystems();
}
