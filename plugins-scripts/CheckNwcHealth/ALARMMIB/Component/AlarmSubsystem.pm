package CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ALARM-MIB', [
      #['models', 'alarmModelTable', 'CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::AlarmModel'],
      #['variables', 'alarmActiveVariableTable', 'CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::AlarmVariable'],
      ['alarms', 'alarmActiveTable', 'CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::Alarm'],
      ['stats', 'alarmActiveStatsTable', 'CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::AlarmStats'],
  ]);
}


package CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::Alarm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::AlarmModel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::AlarmVariable;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
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


package CheckNwcHealth::ALARMMIB::Component::AlarmSubsystem::AlarmStats;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "there are %d active alarms",
      $self->{alarmActiveStatsActiveCurrent});
  if ($self->{alarmActiveStatsActiveCurrent}) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

