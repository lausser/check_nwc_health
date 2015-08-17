package Classes::Alcatel::OmniAccess::Component::AlarmSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ALARM-MIB', [
      ['alarms', 'alarmActiveTable', 'Classes::Alcatel::OmniAccess::Component::AlarmSubsystem::Alarm'],
      ['stats', 'alarmActiveStatsTable', 'Classes::Alcatel::OmniAccess::Component::AlarmSubsystem::AlarmStats'],
  ]);
}


package Classes::Alcatel::OmniAccess::Component::AlarmSubsystem::AlarmStats;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf "there are %d active alarms",
      $self->{alarmActiveStatsActiveCurrent});
  if ($self->{alarmActiveStatsActiveCurrent}) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

