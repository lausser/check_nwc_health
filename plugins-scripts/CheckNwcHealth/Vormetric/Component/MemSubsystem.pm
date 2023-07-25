package CheckNwcHealth::Vormetric::Component::MemSubsystem;
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
        # default is 1024bytes, but it may change
        $self->{$column} *= 8 * $self->number_of_bits("KB");
      }
    }
  }
  $self->{total} = $self->{free} + $self->{buff} + $self->{cache} + $self->{swpd};
  $self->{mem_free_pct} = $self->{free} / $self->{total} * 100;
  $self->{mem_used_pct} = 100 - $self->{mem_free_pct};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory used is %.2f%%',
      $self->{mem_used_pct});
  $self->set_thresholds(
      metric => 'mem_used_pct',
      warning => 80,
      critical => 90);
  $self->add_message($self->check_thresholds(
      metric => 'mem_used_pct',
      value => $self->{mem_used_pct}));
  $self->add_perfdata(
      label => 'mem_used_pct',
      value => $self->{mem_used_pct},
      uom => '%',
  );
}

__END__
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0  29696 778556 271924 1014372    0    0     0     1    1    1  1  0 99  0  0

