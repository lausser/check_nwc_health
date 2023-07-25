package CheckNwcHealth::FabOS::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  foreach (qw(swCpuUsage swCpuNoOfRetries swCpuUsageLimit swCpuPollingInterval
      swCpuAction)) {
    $self->{$_} = $self->valid_response('SW-MIB', $_, 0);
  }
  $self->get_snmp_objects('SW-MIB', (qw(
      swFwFabricWatchLicense)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  if (defined $self->{swCpuUsage}) {
    my $maps = $self->{swCpuUsageLimit} == 0 ?
        'enabled' : 'disabled';
    $self->add_info(sprintf 'maps is %s', $maps);
    $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{swCpuUsage});
    $self->set_thresholds(
        metric => 'cpu_usage',
        warning => $maps eq 'enabled' ? 80 : $self->{swCpuUsageLimit},
        critical => $maps eq 'enabled' ? 90 : $self->{swCpuUsageLimit});
    $self->add_message($self->check_thresholds(
        metric => 'cpu_usage',
        value => $self->{swCpuUsage},
    ));
    $self->add_perfdata(
        label => 'cpu_usage',
        value => $self->{swCpuUsage},
        uom => '%',
    );
  } elsif ($self->{swFwFabricWatchLicense} eq 'swFwNotLicensed') {
    $self->add_unknown('please install a fabric watch license');
  } else {
    my $swFirmwareVersion = $self->get_snmp_object('SW-MIB', 'swFirmwareVersion');
    if ($swFirmwareVersion && $swFirmwareVersion =~ /^v6/) {
      $self->add_ok('cpu usage is not implemented');
    } else {
      $self->add_unknown('cannot aquire cpu usage');
    }
  }
}

