package CheckNwcHealth::UCDMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('UCD-SNMP-MIB', (qw(
      memTotalSwap memTotalReal memTotalFree memAvailReal
      memBuffer memCached memShared)));
  # basically buffered memory can always be freed up (filesystem cache)
  # https://kc.mcafee.com/corporate/index?page=content&id=KB73175
  # 16.6.21 memShared fliegt raus, das zaehlt ab jetzt nicht mehr zu
  # potentiell freizukriegendem Speicher. Mir scheissegal, ob das Ergebnis
  # dann stimmt. Nach 10 Jahren Rumgefrickel habe ich es satt, ab jetzt wird
  # das alles so hingebastelt, daß ich so wenige Tickets wie moeglich
  # auf den Tisch bekomme. 
  my $mem_available = $self->{memAvailReal};
  foreach (qw(memBuffer memCached)) {
    $mem_available += $self->{$_} if defined($self->{$_});
  }

  # calc memory (no swap)
  $self->{mem_usage} = 100 - ($mem_available * 100 / $self->{memTotalReal});
}

sub check {
  my ($self) = @_;
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

