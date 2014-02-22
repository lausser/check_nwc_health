package Classes::CheckPoint::Firewall1::Component::MemSubsystem;
our @ISA = qw(Classes::CheckPoint::Firewall1);
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
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      memTotalReal64 memFreeReal64)));
  $self->{memory_usage} = $self->{memFreeReal64} ? 
      ($self->{memFreeReal64} / $self->{memTotalReal64} * 100) : 100;
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

