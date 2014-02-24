package Classes::CiscoAsyncOS::Component::MemSubsystem;
our @ISA = qw(Classes::CiscoAsyncOS);
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
  my %params = @_;
  $self->get_snmp_objects('ASYNCOS-MAIL-MIB', (qw(
      perCentMemoryUtilization memoryAvailabilityStatus)));
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m');
  my $info = sprintf 'memory usage is %.2f%% (%s)',
      $self->{perCentMemoryUtilization}, $self->{memoryAvailabilityStatus};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  if ($self->check_thresholds($self->{perCentMemoryUtilization})) {
    $self->add_message($self->check_thresholds($self->{perCentMemoryUtilization}), $info);
  } elsif ($self->{memoryAvailabilityStatus} eq 'memoryShortage') {
    $self->add_warning($info);
    $self->set_thresholds(warning => $self->{perCentMemoryUtilization}, critical => 90);
  } elsif ($self->{memoryAvailabilityStatus} eq 'memoryFull') {
    $self->add_critical($info);
    $self->set_thresholds(warning => 80, critical => $self->{perCentMemoryUtilization});
  } else {
    $self->add_ok($info);
  }
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{perCentMemoryUtilization},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}


sub dump {
  my $self = shift;
  printf "[MEMORY]\n";
  printf "perCentMemoryUtilization: %s\n", $self->{perCentMemoryUtilization};
  printf "memoryAvailabilityStatus: %s\n", $self->{memoryAvailabilityStatus};
}


