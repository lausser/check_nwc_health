package Classes::Cisco::CISCOENTITYALARMMIB::Component::AlarmSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $alarms = {};
  $self->get_snmp_tables('CISCO-ENTITY-ALARM-MIB', [
    ['alarms', 'ceAlarmTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::Alarm', sub { my ($o) = @_; $o->{parent} = $self; $self->filter_name($o->{entPhysicalIndex})}],
    ['alarmdescriptionmappings', 'ceAlarmDescrMapTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmDescriptionMapping' ],
    ['alarmdescriptions', 'ceAlarmDescrTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmDescription' ],
    ['alarmfilterprofiles', 'ceAlarmFilterProfileTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmFilterProfile' ],
    ['alarmhistory', 'ceAlarmHistTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmHistory', sub { my ($o) = @_; $o->{parent} = $self; $self->filter_name($o->{entPhysicalIndex})}],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::PhysicalEntity'],
  ]);
  $self->get_snmp_objects('CISCO-ENTITY-ALARM-MIB', qw(
      ceAlarmCriticalCount ceAlarmMajorCount ceAlarmMinorCount
      ceAlarmFilterProfileIndexNext
  ));
  foreach (qw(ceAlarmCriticalCount ceAlarmMajorCount ceAlarmMinorCount)) {
    $self->{$_} ||= 0;
  }
  @{$self->{alarms}} = grep { 
      $_->{ceAlarmSeverity} ne 'none' &&
      $_->{ceAlarmSeverity} ne 'info'
  } @{$self->{alarms}};
  foreach my $alarm (@{$self->{alarms}}) {
    foreach my $entity (@{$self->{entities}}) {
      if ($alarm->{entPhysicalIndex} eq $entity->{entPhysicalIndex}) {
        $alarm->{entity} = $entity;
      }
    }
  }
}

sub check {
  my ($self) = @_;
  if (scalar(@{$self->{alarms}}) == 0) {
    $self->add_info('no alarms');
    $self->add_ok();
  } else {
    foreach (@{$self->{alarms}}) {
      $_->check();
    }
    foreach (@{$self->{alarmhistory}}) {
      $_->check();
    }
    if (! $self->check_messages()) { # blacklisted des ganze glump
      $self->add_info('no alarms');
      $self->add_ok();
    }
  }
}

package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::Alarm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{entPhysicalIndex} = $self->{flat_indices};
  $self->{ceAlarmTypes} = [];
  if ($self->{ceAlarmList}) {
    my $index = 0;
    foreach my $octet (unpack('H2', $self->{ceAlarmList})) {
      my $hexoctet = hex($octet) & 0xff;
      if ($hexoctet) {
        my $base = 8 * $index;
        foreach my $bit (0..7) {
          my $mask = (2 ** $bit) & 0xff;
          if ($hexoctet & $mask) {
            push(@{$self->{ceAlarmTypes}}, $base + $bit);
          }
        }
      }
      $index++;
    }
  }
  $self->{ceAlarmTypes} = join(",", @{$self->{ceAlarmTypes}}); # weil sonst der drecks-dump nicht funktioniert.
}

sub check {
  my ($self) = @_;
  my $location = exists $self->{entity} ?
      $self->{entity}->{entPhysicalDescr} : "unknown";
  if (length($self->{ceAlarmTypes})) {
    my @descriptorindexes = map {
        $_->{ceAlarmDescrIndex}
    } grep {
        $self->{entity}->{entPhysicalVendorType} eq $_->{ceAlarmDescrVendorType}
    } @{$self->{parent}->{alarmdescriptionmappings}};
    if (@descriptorindexes) {
      my $ceAlarmDescrIndex = $descriptorindexes[0];
      my @descriptions = grep {
        $_->{ceAlarmDescrIndex} == $ceAlarmDescrIndex;
      } @{$self->{parent}->{alarmdescriptions}};
      foreach my $ceAlarmType (split(",", $self->{ceAlarmTypes})) {
        foreach my $alarmdesc (@descriptions) {
          if ($alarmdesc->{ceAlarmDescrAlarmType} == $ceAlarmType) {
            $self->add_info(sprintf "%s alarm '%s' in entity %d (%s)",
                $alarmdesc->{ceAlarmDescrSeverity},
                $alarmdesc->{ceAlarmDescrText},
                $self->{entPhysicalIndex},
                $location);
            if ($alarmdesc->{ceAlarmDescrSeverity} eq "none") {
              # A value of '0' indicates that there the corresponding physical entity currently is not asserting any alarms.
            } elsif ($alarmdesc->{ceAlarmDescrSeverity} eq "critical") {
              $self->add_critical();
            } elsif ($alarmdesc->{ceAlarmDescrSeverity} eq "major") {
              $self->add_critical();
            } elsif ($alarmdesc->{ceAlarmDescrSeverity} eq "minor") {
              $self->add_warning();
            } elsif ($alarmdesc->{ceAlarmDescrSeverity} eq "info") {
              $self->add_ok();
            }
          }
        }
      }
    }
  }
  delete $self->{parent}; # brauch ma nimmer, daad eh sched bon dump scheebern
}


package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::PhysicalEntity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{entPhysicalIndex} = $self->{flat_indices};
}

package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmDescription;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{ceAlarmDescrIndex} = $self->{indices}->[0];
  $self->{ceAlarmDescrAlarmType} = $self->{indices}->[1];
}


package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmDescriptionMapping;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{ceAlarmDescrIndex} = $self->{indices}->[0];
}

package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmFilterProfile;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::AlarmHistory;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{ceAlarmHistTimeStamp} = time - $self->uptime() + $self->timeticks($self->{ceAlarmHistTimeStamp});
  $self->{ceAlarmHistTimeStampLocal} = scalar localtime $self->{ceAlarmHistTimeStamp};
}

sub check {
  my ($self) = @_;
  my $vendortype = "unknown";
  my @entities = grep {
    $_->{entPhysicalIndex} == $self->{ceAlarmHistEntPhysicalIndex};
  } @{$self->{parent}->{entities}};
  if (@entities) {
    $vendortype = $entities[0]->{entPhysicalVendorType};
    $self->{ceAlarmHistEntPhysicalDescr} = $entities[0]->{entPhysicalDescr};
  }
  my @descriptorindexes = map {
      $_->{ceAlarmDescrIndex}
  } grep {
      $vendortype eq $_->{ceAlarmDescrVendorType}
  } @{$self->{parent}->{alarmdescriptionmappings}};
  if (@descriptorindexes) {
    my $ceAlarmDescrIndex = $descriptorindexes[0];
    my @descriptions = grep {
      $_->{ceAlarmDescrIndex} == $ceAlarmDescrIndex;
    } @{$self->{parent}->{alarmdescriptions}};
    foreach my $alarmdesc (@descriptions) {
      if ($alarmdesc->{ceAlarmDescrAlarmType} == $self->{ceAlarmHistAlarmType}) {
        $self->{ceAlarmHistAlarmDescrText} = $alarmdesc->{ceAlarmDescrText};
      }
    }
  }
  delete $self->{parent};
}

__END__

ceAlarmTable 
"This table specifies alarm control and status information
related to each physical entity contained by the system,
including the alarms currently being asserted by each physical
entity capable of generating alarms."

ceAlarmEntry 
INDEX { entPhysicalIndex }
"Alarm control and status information related to the 
corresponding physical entity, including a list of those
alarms currently being asserted by that physical entity."

ceAlarmSeverity 
"This object specifies the highest severity alarm currently
being asserted by the corresponding physical entity. A value
of '0' indicates that there the corresponding physical entity
currently is not asserting any alarms."

ceAlarmFilterProfile 
"This object specifies the alarm filter profile associated
with the corresponding physical entity. An alarm filter
profile controls which alarm types the agent will monitor
and signal for the corresponding physical entity.

If the value of this object is '0', then the agent monitors
and signals all alarms associated with the corresponding
physical entity."

ceAlarmList 
If an alarm is being asserted by the physical entity, then the
corresponding bit in the alarm list is set to a one. Observe
that if the physical entity is not currently asserting any
alarms, then the list will have a length of zero."

01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
32 octets
An OCTET STRING represents an alarm list, in which each
bit represents an alarm type. The bits in the first octet
represent alarm types identified by the integer values 1
through 8, inclusive, The bits in the second octet represent
alarm types identified by the integer values 9 through 16,
inclusive, and so forth.
Alternativ:
http://webcache.googleusercontent.com/search?q=cache:H9-CC7j7rxQJ:trbonet.com/download/HelpFile/TRBOnet_Watch_User_Guide_1.9_ENG.pdf+&cd=13&hl=de&ct=clnk&gl=de
4. How to read a list of alarms from a ceAlarmList (ceAlarmTable, Oid: 1.3.6.1.4.1.9.9.138.1.2.5.1.3)

This line consists of 32 bytes in hexadecimal format. Type of alarm is encoded by ordinal bit.

The encoding line may look like this:

00 00 00 00 00 00 00 00 00 00 00 00 00 08 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

I.e. 13 * 8 + 3(00001000) = 107 (PeerDisconnected Alarm).
rechtes bit von oktett 0 = fehler 0
rechtes bit von oktett 1 = fehler 9
also ist rechtes bit von oktett 13 der fehler 104
zweitrechtes bit von oktett 13 der fehler 105 ...

Other types of alarms are defined similarly. If no alarms are set, the line will have zero length.



jetzt wirds dreckig:

AlarmTable
Ein Entry gehoert zu einem entPhysicalIndex
Ein Entry hat ceAlarmList und daraus abgeleitet ceAlarmTypes

Entites
Ein physical Entity hat eindeutig entPhysicalIndex
und hat einen entPhysicalVendorType, also die Bauteilbezeichnung

ceAlarmDescrMapTable ist eine stupide durchnumerierte Tabelle, die
ceAlarmDescrIndex und ceAlarmDescrVendorType- Paerchen buendelt


AlarmTable
mit entPhysicalIndex wird entPhysicalVendorType ermittelt

ceAlarmDescrMapTable
mit entPhysicalVendorType=ceAlarmDescrVendorType wird ceAlarmDescrIndex ermittelt

ceAlarmDescrTable
mit ceAlarmDescrIndex = ceAlarmDescrIndex &&
 ceAlarmTypes aus AlarmTable = ceAlarmDescrAlarmType
wird ceAlarmDescrText geholt

