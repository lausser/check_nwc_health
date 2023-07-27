package CheckNwcHealth::FabOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  foreach (qw(swMemUsage swMemUsageLimit1 swMemUsageLimit3 swMemPollingInterval
      swMemNoOfRetries swMemAction)) {
    $self->{$_} = $self->valid_response('SW-MIB', $_, 0);
  }
  $self->get_snmp_objects('SW-MIB', (qw(
      swFwFabricWatchLicense)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (defined $self->{swMemUsage}) {
    my $maps = (! defined $self->{swMemUsageLimit1} || $self->{swMemUsageLimit1} == 0) &&
        (! defined $self->{swMemUsageLimit3} || $self->{swMemUsageLimit3} == 0) ?
        'enabled' : 'disabled';
    $self->add_info(sprintf 'maps is %s', $maps);
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{swMemUsage});
    $self->set_thresholds(
        metric => 'memory_usage',
        warning => $maps eq 'enabled' ? 80 : $self->{swMemUsageLimit1},
        critical => $maps eq 'enabled' ? 90 : $self->{swMemUsageLimit3});
    $self->add_message($self->check_thresholds(
        metric => 'memory_usage',
        value => $self->{swMemUsage},
    ));
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{swMemUsage},
        uom => '%',
    );
  } elsif ($self->{swFwFabricWatchLicense} eq 'swFwNotLicensed') {
    $self->add_unknown('please install a fabric watch license');
  } else {
    my $swFirmwareVersion = $self->get_snmp_object('SW-MIB', 'swFirmwareVersion');
    if ($swFirmwareVersion && $swFirmwareVersion =~ /^v6/) {
      $self->add_ok('memory usage is not implemented');
    } else {
      $self->add_unknown('cannot aquire memory usage');
    }
  }
}

