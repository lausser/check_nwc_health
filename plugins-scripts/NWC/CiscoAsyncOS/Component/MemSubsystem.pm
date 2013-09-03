package NWC::CiscoAsyncOS::Component::MemSubsystem;
our @ISA = qw(NWC::CiscoAsyncOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    cpus => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  $self->{perCentMemoryUtilization} = $self->get_snmp_object('ASYNCOS-MAIL-MIB', 'perCentMemoryUtilization');
  $self->{memoryAvailabilityStatus} = $self->get_snmp_object('ASYNCOS-MAIL-MIB', 'memoryAvailabilityStatus');
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
    $self->add_message(WARNING, $info);
    $self->set_thresholds(warning => $self->{perCentMemoryUtilization}, critical => 90);
  } elsif ($self->{memoryAvailabilityStatus} eq 'memoryFull') {
    $self->add_message(CRITICAL, $info);
    $self->set_thresholds(warning => 80, critical => $self->{perCentMemoryUtilization});
  } else {
    $self->add_message(OK, $info);
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


