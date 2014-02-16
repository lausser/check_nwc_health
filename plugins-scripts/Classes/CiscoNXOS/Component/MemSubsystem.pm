package Classes::CiscoNXOS::Component::MemSubsystem;
our @ISA = qw(Classes::CiscoNXOS);
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
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  my $type = 0;
  $self->{cseSysMemoryUtilization} = $self->get_snmp_object('CISCO-SYSTEM-EXT-MIB', 'cseSysMemoryUtilization');
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (defined $self->{cseSysMemoryUtilization}) {
    my $info = sprintf 'memory usage is %.2f%%',
        $self->{cseSysMemoryUtilization};
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds($self->{cseSysMemoryUtilization}), $info);
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{cseSysMemoryUtilization},
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
  foreach (qw(cseSysMemoryUtilization)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

