package Classes::FabOS::Component::MemSubsystem;
our @ISA = qw(Classes::FabOS);
use strict;

sub init {
  my $self = shift;
  foreach (qw(swMemUsage swMemUsageLimit1 swMemUsageLimit3 swMemPollingInterval
      swMemNoOfRetries swMemAction)) {
    $self->{$_} = $self->valid_response('SW-MIB', $_, 0);
  }
  $self->get_snmp_objects('SW-MIB', (qw(
      swFwFabricWatchLicense)));
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (defined $self->{swMemUsage}) {
    my $info = sprintf 'memory usage is %.2f%%',
        $self->{swMemUsage};
    $self->add_info($info);
    $self->set_thresholds(warning => $self->{swMemUsageLimit1},
        critical => $self->{swMemUsageLimit3});
    $self->add_message($self->check_thresholds($self->{swMemUsage}), $info);
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{swMemUsage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical}
    );
  } elsif ($self->{swFwFabricWatchLicense} eq 'swFwNotLicensed') {
    $self->add_unknown('please install a fabric watch license');
  } else {
    $self->add_unknown('cannot aquire momory usage');
  }
}

