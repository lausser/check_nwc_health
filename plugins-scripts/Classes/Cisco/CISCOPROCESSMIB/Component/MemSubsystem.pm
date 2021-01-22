package Classes::Cisco::CISCOPROCESSMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-PROCESS-MIB', [
      ['cpumems', 'cpmCPUTotalTable', 'Classes::Cisco::CISCOPROCESSMIB::Component::MemSubsystem::Mem', sub { my $o = shift; return exists $o->{cpmCPUMemoryUsed} ? 1 : 0 } ],
  ]);
}

package Classes::Cisco::CISCOPROCESSMIB::Component::MemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if (! exists $self->{cpmCPUMemoryUsed}) {
    # dann fluigt der ganze scheisdreck weida ohm beim get_snmp_tables
    # ausse. mit wos fir am oltn glump das i mi heid wieder oweerchan mou!
    return;
  }
  $self->{cpmCPUTotalIndex} = $self->{flat_indices};
#  $self->{cpmCPUTotalPhysicalIndex} = exists $self->{cpmCPUTotalPhysicalIndex} ?
#      $self->{cpmCPUTotalPhysicalIndex} : 0;
  $self->{entPhysicalName} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalName', $self->{cpmCPUTotalPhysicalIndex});
  # wichtig fuer gestacktes zeugs, bei dem entPhysicalName doppelt und mehr vorkommen kann
  # This object is a user-assigned asset tracking identifier for the physical entity
  # as specified by a network manager, and provides non-volatile storage of this
  # information. On the first instantiation of an physical entity, the value of
  # entPhysicalAssetID associated with that entity is set to the zero-length string.
  # ...
  # If write access is implemented for an instance of entPhysicalAssetID, and a value
  # is written into the instance, the agent must retain the supplied value in the
  # entPhysicalAssetID instance associated with the same physical entity for as long
  # as that entity remains instantiated. This includes instantiations across all
  # re-initializations/reboots of the network management system, including those
  # which result in a change of the physical entity's entPhysicalIndex value.
  $self->{entPhysicalAssetID} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalAssetID', $self->{cpmCPUTotalPhysicalIndex});
  $self->{entPhysicalDescr} = $self->get_snmp_object('ENTITY-MIB', 'entPhysicalDescr', $self->{cpmCPUTotalPhysicalIndex});
  $self->{name} = $self->{entPhysicalName} || $self->{entPhysicalDescr};
  # letzter Ausweg, weil auch alle drei get_snmp_object fehlschlagen koennen
  $self->{name} ||= $self->{cpmCPUTotalIndex};
  if ($self->{cpmCPUMemoryHCUsed} and $self->{cpmCPUMemoryHCFree}) {
    my $total = $self->{cpmCPUMemoryHCUsed} + $self->{cpmCPUMemoryHCFree};
    $self->{usage} = 100 *  $self->{cpmCPUMemoryHCCommitted} / $total;
  } else {
    $self->{cpmCPUMemoryLCUsed} = $self->{cpmCPUMemoryUsedOvrflw} ?
        ($self->{cpmCPUMemoryUsedOvrflw} << 32) + ($self->{cpmCPUMemoryUsed}) :
        $self->{cpmCPUMemoryUsed};
    $self->{cpmCPUMemoryLCFree} = $self->{cpmCPUMemoryFreeOvrflw} ?
        ($self->{cpmCPUMemoryFreeOvrflw} << 32) + ($self->{cpmCPUMemoryFree}) :
        $self->{cpmCPUMemoryFree};
    my $total = $self->{cpmCPUMemoryLCUsed} + $self->{cpmCPUMemoryLCFree};
    if (exists $self->{cpmCPUMemoryCommitted}) {
      $self->{cpmCPUMemoryLCCommitted} = $self->{cpmCPUMemoryCommittedOvrflw} ?
          ($self->{cpmCPUMemoryCommittedOvrflw} << 32) + ($self->{cpmCPUMemoryCommitted}) :
          $self->{cpmCPUMemoryCommitted};
      $self->{usage} = 100 *  $self->{cpmCPUMemoryLCCommitted} / $total;
    } else {
      $self->{usage} = 100 *  $self->{cpmCPUMemoryLCFree} / $total;
    }
  }
  return $self;
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s memory usage is %.2f%%',
      $self->{name}, $self->{usage});
  my $label = 'cpumem_'.$self->{name}.'_usage';
  $self->set_thresholds(
      metric => $label,
      warning => 80,
      critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{usage},
  ));
  $self->add_perfdata(
      label => $label,
      value => $self->{usage},
      uom => '%',
  );
}

__END__
https://thwack.solarwinds.com/t5/NPM-Feature-Requests/Additional-Cisco-quot-CPU-Memory-quot-Poller-for-Cisco-ASR/idc-p/560968

Memory (kB)
Slot  Status    Total     Used (Pct)     Free (Pct) Committed (Pct)
  RP0 Healthy  3969316  3849744 (97%)   119572 ( 3%)  2582596 (65%)

In this output, the "Committed" output is what we recommend focusing on, as this represents what memory processes have actually requested from the kernel. The "Used" value, on the other hand, appears high because this includes the Linux kernel cache: this "extra" memory is used by the kernel to store bits of frequently used data, but that memory can be freed at any time if needed. From the perspective of committed memory, this router is not low on memory and appears to be operating normally.

We frequently see cases inquiring about the misleadingly high value in the "Used" column. As a result, this is being adjusted in later code to provide a better representation of what memory is actually available for use. Additionally, two bugs have been filled to document the behavior, these are CSCuc40262 and CSCuv32343:
