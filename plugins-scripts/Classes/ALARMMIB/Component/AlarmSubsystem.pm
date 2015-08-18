package Classes::ALARMMIB::Component::AlarmSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ALARM-MIB', [
      #['models', 'alarmModelTable', 'Classes::ALARMMIB::Component::AlarmSubsystem::AlarmModel'],
      #['variables', 'alarmActiveVariableTable', 'Classes::ALARMMIB::Component::AlarmSubsystem::AlarmVariable'],
      ['alarms', 'alarmActiveTable', 'Classes::ALARMMIB::Component::AlarmSubsystem::Alarm'],
      ['stats', 'alarmActiveStatsTable', 'Classes::ALARMMIB::Component::AlarmSubsystem::AlarmStats'],
  ]);
}


package Classes::ALARMMIB::Component::AlarmSubsystem::Alarm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::ALARMMIB::Component::AlarmSubsystem::AlarmModel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::ALARMMIB::Component::AlarmSubsystem::AlarmVariable;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{ceAlarmTypes} = [];
  if ($self->{alarmActiveVariableValueType} eq 'octetString') {
    my $index = 0;
    $self->{alarmActiveVariableOctetStringVal2} = join("", map {
      chr(hex($_));
    } map {
      /0x(\w+)/ ? $1 : $_;
    } split(/\s+/, $self->{alarmActiveVariableOctetStringVal}));
  }
}


package Classes::ALARMMIB::Component::AlarmSubsystem::AlarmStats;
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

