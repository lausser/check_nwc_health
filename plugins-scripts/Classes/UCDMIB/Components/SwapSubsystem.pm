package Classes::UCDMIB::Component::SwapSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('UCD-SNMP-MIB', (qw(
      memTotalSwap memAvailSwap memMinimumSwap
      memSwapError memSwapErrorMsg)));

  # calc swap usage
  eval {
    $self->{swap_usage} = 100 - ($self->{memAvailSwap} * 100 / $self->{memTotalSwap});
  };
}

sub check {
  my $self = shift;
  if (defined $self->{'swap_usage'}) {
    $self->add_info(sprintf 'swap usage is %.2f%%',
        $self->{swap_usage});
    $self->set_thresholds(
      metric => 'swap_usage',
      warning => int(100 - ($self->{memMinimumSwap} * 100 / $self->{memTotalSwap})),
      critical => int(100 - ($self->{memMinimumSwap} * 100 / $self->{memTotalSwap}))
    );
    $self->add_message($self->check_thresholds(
        metric => 'swap_usage',
        value => $self->{swap_usage}));
    $self->add_perfdata(
        label => 'swap_usage',
        value => $self->{swap_usage},
        uom => '%',
    );
    if ($self->{'memSwapError'} eq 'error') {
      $self->add_critical('SwapError: ' . $self->{'memSwapErrorMsg'});
    }
  } else {
    # $self->add_unknown('cannot aquire swap usage');
    # This system does not use swap
  }
}

