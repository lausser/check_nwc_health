package Classes::CiscoAsyncOS::Component::CpuSubsystem;
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
  $self->{perCentCPUUtilization} = $self->get_snmp_object('ASYNCOS-MAIL-MIB', 'perCentCPUUtilization');
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  $self->blacklist('c');
  my $info = sprintf 'cpu usage is %.2f%%',
      $self->{perCentCPUUtilization};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{perCentCPUUtilization}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{perCentCPUUtilization},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  printf "perCentCPUUtilization: %s\n", $self->{perCentCPUUtilization};
}


