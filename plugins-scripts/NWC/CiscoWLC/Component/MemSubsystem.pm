package NWC::CiscoWLC::Component::MemSubsystem;
our @ISA = qw(NWC::CiscoWLC);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
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
  my $type = 0;
  $self->{total_memory} = $self->get_snmp_object(
      'AIRESPACE-SWITCHING-MIB', 'agentTotalMemory');
  $self->{free_memory} = $self->get_snmp_object(
      'AIRESPACE-SWITCHING-MIB', 'agentFreeMemory');
  $self->{memory_usage} = $self->{free_memory} ? 
      ($self->{free_memory} / $self->{total_memory} * 100) : 100;
}

sub check {
  my $self = shift;
  my $info = sprintf 'memory usage is %.2f%%',
      $self->{memory_usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{memory_usage}), $info);
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{memory_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(memory_usage total_memory free_memory)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

