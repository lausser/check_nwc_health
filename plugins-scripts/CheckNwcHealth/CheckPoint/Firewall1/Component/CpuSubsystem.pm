package CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(procUsage procNum svnVersion)));
  $self->{procQueue} = $self->valid_response('CHECKPOINT-MIB', 'procQueue');
  if ($self->{svnVersion} eq "R81.20") {
    # R81.20 is pretty broken. It returns multiProcUsage which are mostly
    # 0, 20, 25, 50, 100 etc. Rarely we get reasonable values.
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
  my $num_non_random = 0;
  if (scalar(@{$self->{multiprocs}})) {
    my @percentages = map {
        $_->{multiProcUsage};
    } @{$self->{multiprocs}};
    my %frequency;
    $frequency{$_}++ for @percentages;
    my $total = @percentages;
    my $entropy = 0;
    foreach my $count (values %frequency) {
        my $p_x = $count / $total;
        $entropy -= $p_x * (log($p_x) / log(2));
    }
    $self->debug(sprintf "entropy is %f", $entropy);
  }
