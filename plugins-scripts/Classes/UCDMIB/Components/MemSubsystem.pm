package Classes::UCDMIB::Component::MemSubsystem;
our @ISA = qw(Classes::UCDMIB);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  foreach (qw(memTotalSwap memAvailSwap memTotalReal memAvailReal memTotalFree)) {
    $self->{$_} = $self->get_snmp_object('UCD-SNMP-MIB', $_, 0);
  }
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
    my $info = sprintf 'memory usage is %.2f%%',
        $self->{mem_usage};
    $self->add_info($info);
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
    $self->add_message(UNKNOWN, 'cannot aquire momory usage');
  }
}

sub dump {
  my $self = shift;
  printf "[MEMORY]\n";
  foreach (qw(memTotalSwap memAvailSwap memTotalReal memAvailReal memTotalFree)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

