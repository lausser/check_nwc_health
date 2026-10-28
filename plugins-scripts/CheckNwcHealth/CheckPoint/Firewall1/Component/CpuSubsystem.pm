package CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(procUsage procNum svnVersion)));
  $self->{procQueue} = $self->valid_response('CHECKPOINT-MIB', 'procQueue');

  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['updates', 'updatesInstalledTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem::Take'],
  ]);

  my $take_number;
  foreach (@{$self->{updates}}) {
    if (defined $_->{takeNumber} &&
        (!defined $take_number || $_->{takeNumber} > $take_number)) {
      $take_number = $_->{takeNumber};
    }
  }

  my $use_checkpoint_multiprocs = $self->{svnVersion} ne 'R81.20';
  if ($self->{svnVersion} eq 'R81.20') {
    if (defined $take_number && $take_number >= 115) {
      $use_checkpoint_multiprocs = 1;
      $self->debug('R81.20 Jumbo Take %d detected; using CHECKPOINT-MIB multiProcUsage for per-core CPU metrics',
          $take_number);
    } elsif (defined $take_number) {
      $self->debug('R81.20 Jumbo Take %d is below required Take 115; using HOST-RESOURCES-MIB hrProcessorLoad for per-core CPU metrics',
          $take_number);
    } else {
      $self->debug('R81.20 Jumbo Take could not be determined from updatesInstalledTable; using HOST-RESOURCES-MIB hrProcessorLoad for per-core CPU metrics');
    }
  } else {
    $self->debug('%s is not R81.20; using CHECKPOINT-MIB multiProcUsage for per-core CPU metrics',
        $self->{svnVersion});
  }

  if (!$use_checkpoint_multiprocs) {
    # Before R81.20 Jumbo Take 115, multiProcUsage can return incorrect
    # values. Fall back to HOST-RESOURCES-MIB for the per-core perfdata.
    $self->get_snmp_tables('HOST-RESOURCES-MIB', [
        ['cpus', 'hrProcessorTable', 'CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem::Cpu'],
    ]);
    my $idx = 1;
    foreach (@{$self->{cpus}}) {
      my $cpu = CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem::MultiProc->new(
        multiProcIndex => $idx++,
        multiProcUsage => $_->{hrProcessorLoad},
      );
      push(@{$self->{multiprocs}}, $cpu);
    }
    delete $self->{cpus};
  } else {
    $self->get_snmp_tables('CHECKPOINT-MIB', [
        ['multiprocs', 'multiProcTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem::MultiProc'],
    ]);
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{procUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{procUsage}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{procUsage},
      uom => '%',
  );
  if (defined $self->{procQueue}) {
    $self->add_perfdata(
        label => 'cpu_queue_length',
        value => $self->{procQueue},
        thresholds => 0,
    );
  }
  $self->add_info('checking cpu cores');
  if (@{$self->{multiprocs}}) {
    foreach (@{$self->{multiprocs}}) {
      $_->check();
    }
  }
}

package CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem::Take;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if (defined $self->{updatesInstalledType} &&
      $self->{updatesInstalledType} eq 'Wrapper' &&
      defined $self->{updatesInstalledName} &&
      $self->{updatesInstalledName} =~
          /^Check_Point_R81_20_jumbo_hf_main_Bundle_T(\d+)_FULL\.tgz$/i) {
    $self->{takeNumber} = $1;
  }
  return $self;
}

package CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem::MultiProc;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $label = sprintf 'cpu_core_%s_usage', $self->{multiProcIndex};
  $self->add_info(sprintf 'cpu core %s usage is %.2f%%',
      $self->{multiProcIndex},
      $self->{multiProcUsage});
    $self->set_thresholds(metric => $label, warning => 80, critical => 90);
    $self->add_message($self->check_thresholds(metric => $label, value => $self->{multiProcUsage}));
    $self->add_perfdata(
        label => $label,
        value => $self->{multiProcUsage},
        uom => '%',
    );
}

__END__

=head1 R81.20 CPU core metric source

C<procUsage> remains the aggregate CPU metric and is always read from
C<CHECKPOINT-MIB>. This component selects only the source of the per-core
C<C<cpu_core_*_usage>> perfdata.

For R81.20, it walks C<updatesInstalledTable>
(C<1.3.6.1.4.1.2620.1.6.20.7>). The installed Jumbo Hotfix Accumulator is
the row whose C<updatesInstalledType> is C<Wrapper> and whose package name is
C<Check_Point_R81_20_jumbo_hf_main_Bundle_T<take>_FULL.tgz>. The C<Take>
table item extracts C<< takeNumber >> from that filename.

Check Point's R81.20 Jumbo Hotfix Accumulator resolved-issues list documents
separate C<multiProcUsage> fixes in Takes 79, 111, and 115. Take 115 fixes
wrong values when HyperFlow is enabled. As the plugin cannot reliably detect
HyperFlow through SNMP, it uses C<CHECKPOINT-MIB::multiProcUsage> only for an
installed R81.20 Wrapper Take of 115 or later. R81.20 devices with no usable
Wrapper row, an unrecognised package name, or an older Take use
C<HOST-RESOURCES-MIB::hrProcessorLoad> for per-core perfdata instead.

=head2 R81.20 CPU-related Jumbo Takes

  Take  Finding                                           Source-selection effect
  ----  ------------------------------------------------  --------------------------------------------
  79    multiProcUsage can return an incorrect value.     First direct repair, but later fixes apply.
  99    High SND/RAD CPU in specific traffic scenarios.   Actual workload behaviour; no source change.
  111   multiProcUsage can falsely report high CPU.        Direct repair, but HyperFlow remains relevant.
  115   multiProcUsage is wrong with HyperFlow enabled.    Minimum automatic Take: use >= 115.
  118   Multicast VPN traffic can cause high SND CPU.      Actual workload behaviour; no source change.
  120   CPView multicore VSX CPU calculation is wrong.     CPView validation caveat; no source change.
  146   SNMP can incorrectly report 100% CPU.              OID unspecified; retain a manual override.
  158   CPView CPU information can be absent for VSes.     CPView display issue; no source change.

The source-selection policy is therefore:

  R81.20 Wrapper Take >= 115       CHECKPOINT-MIB::multiProcUsage
  R81.20 missing, invalid, < 115   HOST-RESOURCES-MIB::hrProcessorLoad

The release-note entries are cumulative. The exact per-core OID is fixed in
Take 79, a false-high calculation is fixed in Take 111, and the
HyperFlow-specific error is fixed in Take 115. As HyperFlow cannot be
reliably determined through SNMP, Take 115 is the conservative automatic
floor.

=head2 Sources

  R81.20 all resolved issues and new features:
  https://sc1.checkpoint.com/documents/Jumbo_HFA/R81.20/All_Resolved_Issues.html

  R81.20 Jumbo Take 111:
  https://sc1.checkpoint.com/documents/Jumbo_HFA/R81.20/R81.20/Take_111.htm

  R81.20 critical information:
  https://sc1.checkpoint.com/documents/Jumbo_HFA/R81.20/Critical_Information.html

=cut
