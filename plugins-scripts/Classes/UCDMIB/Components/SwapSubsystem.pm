package Classes::UCDMIB::Component::SwapSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my %params = @_;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['swap', 'memory', 'Classes::UCDMIB::Component::SwapSubsystem::Swap'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking swap');
  foreach (@{$self->{swap}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{swap}}) {
    $_->dump();
  }
}

package Classes::UCDMIB::Component::SwapSubsystem::Swap;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  # calc swap usage
  eval {
    $self->{swap_usage} = 100 - ($self->{memAvailSwap} * 100 / $self->{memTotalSwap});
  };

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

