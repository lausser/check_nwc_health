package Classes::Juniper::NetScreen::Component::MemSubsystem;
our @ISA = qw(Classes::Juniper::NetScreen);
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
  $self->get_snmp_objects('NETSCREEN-RESOURCE-MIB', (qw(
      nsResMemAllocate nsResMemLeft nsResMemFrag)));
  my $mem_total = $self->{nsResMemAllocate} + $self->{nsResMemLeft};
  $self->{mem_usage} = $self->{nsResMemAllocate} / $mem_total * 100;
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
  foreach (qw(nsResMemAllocate nsResMemLeft nsResMemFrag)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

