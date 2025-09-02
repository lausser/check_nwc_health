package CheckNwcHealth::Lancom::LCOSSX::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('LCOS-SX-MIB', (qw(lcsSystemInfoCPULoad)));
  $self->{cpu_load} = undef;
  # Parse the different time intervals
  # Pattern matches: "100ms:4%, 1s:4%, 10s:7%"
  my %cpu_loads;
  while ($self->{lcsSystemInfoCPULoad} =~ /(\d+(?:ms|s)):(\d+)%/g) {
    my ($interval, $percentage) = ($1, $2);
    $cpu_loads{$interval} = $percentage;
  }
        
    # Return the 10-second average (best for 5-minute polling)
  if (exists $cpu_loads{'10s'}) {
    $self->{cpu_load} = $cpu_loads{'10s'};
  } elsif (exists $cpu_loads{'1s'}) {
    $self->{cpu_load} = $cpu_loads{'1s'};
  } elsif (exists $cpu_loads{'100ms'}) {
    $self->{cpu_load} = $cpu_loads{'100ms'};
  }
  $self->add_unknown("no usable cpu load found") if ! defined $self->{cpu_load};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  # the oid is called ...load...,
  # but as it is in percent, let's call it usage.
  $self->add_info(sprintf 'cpu usage is %.2f%%',
      $self->{cpu_load});
  $self->set_thresholds(
      metric => 'cpu_usage',
      warning => 80,
      critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => 'cpu_usage',
      value => $self->{cpu_load},
  ));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_load},
      uom => '%',
  );
}

