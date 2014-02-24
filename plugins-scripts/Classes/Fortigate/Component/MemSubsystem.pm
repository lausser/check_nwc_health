package Classes::Fortigate::Component::MemSubsystem;
our @ISA = qw(Classes::Fortigate);
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
  $self->get_snmp_objects('FORTINET-FORTIGATE-MIB', (qw(
      fgSysMemUsage)));
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (defined $self->{fgSysMemUsage}) {
    my $info = sprintf 'memory usage is %.2f%%',
        $self->{fgSysMemUsage};
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds($self->{fgSysMemUsage}), $info);
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{fgSysMemUsage},
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
  foreach (qw(fgSysMemUsage)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

