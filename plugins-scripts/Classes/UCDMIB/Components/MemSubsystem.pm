package Classes::UCDMIB::Component::MemSubsystem;
our @ISA = qw(Classes::UCDMIB);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('UCD-SNMP-MIB', (qw(
      memTotalSwap memAvailSwap memTotalReal memAvailReal memTotalFree)));
  # https://kc.mcafee.com/corporate/index?page=content&id=KB73175
  $self->{mem_usage} = ($self->{memTotalReal} - $self->{memTotalFree}) /
      $self->{memTotalReal} * 100;
  $self->{mem_usage} = $self->{memAvailReal} * 100 / $self->{memTotalReal};
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (defined $self->{mem_usage}) {
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{mem_usage});
    $self->set_thresholds(warning => 80,
        critical => 90);
    $self->add_message($self->check_thresholds($self->{mem_usage}), $info);
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{mem_usage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical}
    );
  } else {
    $self->add_unknown('cannot aquire momory usage');
  }
}

