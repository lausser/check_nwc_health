package CheckNwcHealth::Cisco::CISCOENTITYQFPMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-ENTITY-QFP-MIB', [
      ['qmems', 'ceqfpMemoryResourceTable', 'CheckNwcHealth::Cisco::CISCOENTITYQFPMIB::Component::MemSubsystem::QfpMem'],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'CheckNwcHealth::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::PhysicalEntity', sub { my $o = shift; $o->{entPhysicalClass} eq "cpu"; }, ["entPhysicalIndex", "entPhysicalName", "entPhysicalClass"]],
  ]);
  $self->merge_tables_with_code("qmems", "entities", sub {
    my ($qmem, $entity) = @_;
    my $truncated_indices = $qmem->{flat_indices} =~ s/\.\d+$//r;
    return $truncated_indices eq $entity->{flat_indices} ? 1 : 0;
  });
  @{$self->{qmems}} = grep {
    $_->{ceqfpMemoryResType};
  } @{$self->{qmems}};
}

package CheckNwcHealth::Cisco::CISCOENTITYQFPMIB::Component::MemSubsystem::QfpMem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  # index nr2 ist der Typ. Da aber nur ein einziger davon dokumentiert ist,
  # 1=dram, sind alle anderen irgendwelche Geistereintraege. Im konkreten Fall
  # gibt es eine Zeile mit 9001.2, welche aber auch keine Memory-Werte hat.
  # Sowas wird oben im init() rausgefiltert.
  $self->{ceqfpMemoryResType} = $self->mibs_and_oids_definition(
      'CISCO-ENTITY-QFP-MIB', 'CiscoQfpMemoryResource', $self->{indices}->[1]);
  if (defined $self->{ceqfpMemoryHCResInUse}) {
    if ($self->{ceqfpMemoryHCResFree} + $self->{ceqfpMemoryHCResInUse} == 0) {
      $self->{usage} = 0;
    } else {
      $self->{usage} = 100 * $self->{ceqfpMemoryHCResInUse} /
          ($self->{ceqfpMemoryHCResFree} + $self->{ceqfpMemoryHCResInUse});
    }
  } else {
    $self->{usage} =
        ($self->{ceqfpMemoryResFree} + $self->{ceqfpMemoryResInUse}) == 0 ? 0 :
	100 * $self->{ceqfpMemoryResInUse} /
        ($self->{ceqfpMemoryResFree} + $self->{ceqfpMemoryResInUse});
  }
  $self->{name} = $self->{ceqfpMemoryResType}."_".$self->{flat_indices}
      if $self->{ceqfpMemoryResType};
}

sub check {
  my ($self) = @_;
  # entPhysicalName kommt erst nach dem mergen zustande
  $self->{name} = $self->{entPhysicalName} =~ s/\s+/_/gr if $self->{entPhysicalName};
  $self->add_info(sprintf '%s %s usage is %.2f%%',
      $self->{ceqfpMemoryResType}, $self->{name}, $self->{usage});
  $self->set_thresholds(
      metric => $self->{name}.'_usage',
      warning => 80,
      critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => $self->{name}.'_usage',
      value => $self->{usage},
  ));
  $self->add_perfdata(
      label => $self->{name}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

