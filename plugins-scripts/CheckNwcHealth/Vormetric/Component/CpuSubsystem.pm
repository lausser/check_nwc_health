package CheckNwcHealth::Vormetric::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('VORMETRIC-MIB', (qw(vmstat)));
  my @columns = ();
  foreach my $line (split(/\n/, $self->{vmstat})) {
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    if ($line =~ /free/) {
      @columns = split(/\s+/, $line);
    } elsif ($line =~ /^[\d\s]+$/) {
      my @metrics = split(/\s+/, $line);
      while (@columns) {
        my $column = shift @columns;
        $self->{$column} = shift @metrics;
      }
    }
  }
  $self->{busy} = $self->{us} + $self->{sy};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpu');
  $self->add_info(sprintf 'cpu is %.2f%% busy', $self->{busy});
  $self->set_thresholds(
      metric => 'cpu_busy',
      warning => 90,
      critical => 95);
  $self->add_message($self->check_thresholds(
      metric => 'cpu_busy',
      value => $self->{busy}));
  $self->add_perfdata(
      label => 'cpu_busy',
      value => $self->{busy},
      uom => '%',
  );
  $self->add_info(sprintf '(%.2f%% io wait)', $self->{wa});
  $self->set_thresholds(
      metric => 'cpu_iowait',
      warning => 10,
      critical => 20);
  $self->add_message($self->check_thresholds(
      metric => 'cpu_iowait',
      value => $self->{wa}));
  $self->add_perfdata(
      label => 'cpu_iowait',
      value => $self->{wa},
      uom => '%',
  );
}

__END__
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0  29696 778556 271924 1014372    0    0     0     1    1    1  1  0 99  0  0

