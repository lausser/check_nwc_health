package Classes::FabOS::Component::CpuSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  foreach (qw(swCpuUsage swCpuNoOfRetries swCpuUsageLimit swCpuPollingInterval
      swCpuAction)) {
    $self->{$_} = $self->valid_response('SW-MIB', $_, 0);
  }
  $self->get_snmp_objects('SW-MIB', (qw(
      swFwFabricWatchLicense)));
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('c', undef);
  if (defined $self->{swCpuUsage}) {
    $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{swCpuUsage});
    $self->set_thresholds(warning => $self->{swCpuUsageLimit},
        critical => $self->{swCpuUsageLimit});
    $self->add_message($self->check_thresholds($self->{swCpuUsage}), $info);
    $self->add_perfdata(
        label => 'cpu_usage',
        value => $self->{swCpuUsage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
  } elsif ($self->{swFwFabricWatchLicense} eq 'swFwNotLicensed') {
    $self->add_unknown('please install a fabric watch license');
  } else {
    $self->add_unknown('cannot aquire momory usage');
  }
}

