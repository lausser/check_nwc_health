package Classes::UCDMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('UCD-SNMP-MIB', (qw(
      memTotalSwap memAvailSwap memTotalReal memAvailReal memBuffer memCached
      memMinimumSwap memSwapError memSwapErrorMsg)));

  # basically buffered memory can always be freed up (filesystem cache)
  # https://kc.mcafee.com/corporate/index?page=content&id=KB73175
  my $mem_available = $self->{memAvailReal};
  foreach (qw(memBuffer memCached)) {
    $mem_available += $self->{$_} if defined($self->{$_});
  }

  # calc memory (no swap)
  $self->{mem_usage} = 100 - ($mem_available * 100 / $self->{memTotalReal});
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  if (defined $self->{mem_usage}) {
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{mem_usage});
    $self->set_thresholds(
        metric => 'memory_usage',
        warning => 80,
        critical => 90);
    $self->add_message($self->check_thresholds(
        metric => 'memory_usage',
        value => $self->{mem_usage}));
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{mem_usage},
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot aquire memory usage');
  }
}

