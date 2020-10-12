package Classes::Vormetric::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{filesystems} = [];
  $self->get_snmp_objects('VORMETRIC-MIB', (qw(diskUsage)));
  foreach my $line (split(/\n/, $self->{diskUsage})) {
    if ($line =~ /(.*?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.*)/) {
      push(@{$self->{filesystems}},
          Classes::Vormetric::Component::DiskSubsystem::Filesystem->new(
              device => $1,
              size => $2 * 1024*1024,
              used => $3 * 1024*1024,
              available => $4 * 1024*1024,
              usedpct => $5,
              mountpoint => $6,
          ));
    }
  }
}


package Classes::Vormetric::Component::DiskSubsystem::Filesystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{freepct} = 100 - $self->{usedpct};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s has %d%% free space",
      $self->{mountpoint}, $self->{freepct});
  my $label = $self->{mountpoint}."_free_pct";
  $self->set_thresholds(
      metric => $label,
      warning => "10:",
      critical => "5:",
  );
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{freepct}));
  $self->add_perfdata(
      label => $label,
      value => $self->{freepct},
      uom => "%",
  );
}

