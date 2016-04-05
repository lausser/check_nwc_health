package Classes::UCDMIB::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['disks', 'dskTable', 'Classes::UCDMIB::Component::DiskSubsystem::Disk',
          sub {
            my $self = shift;
            # limit disk checks to specific disks. could be improvied by
            # checking the path first and then request the table by indizes
            if ($self->opts->name) {
              if ($self->opts->regexp) {
                my $pattern = $self->opts->name;
                return $self->{dskTotal} && $self->{dskPath} =~ /$pattern/i;
              } else {
                return $self->{dskTotal} && grep { $_ eq $self->{dskPath} }
                    split ',', $self->opts->name;
              }
            } else {
              return $self->{dskTotal} &&
                  $self->{dskDevice} !~ /^(sysfs|proc|udev|devpts|rpc_pipefs|nfsd|devfs)$/;
            }
          }
      ],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking disks');
  if (scalar(@{$self->{disks}}) == 0) {
    $self->add_unknown('no disks');
    return;
  }
  foreach (@{$self->{disks}}) {
    $_->check();
  }
}

package Classes::UCDMIB::Component::DiskSubsystem::Disk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  # support large disks > 2tb
  my $free = 100 * $self->{dskAvail} / $self->{dskTotal};
  $free = 100 - $self->{dskPercent} if $self->{dskTotal} >= 2147483647;
  # define + set threshold
  my $warn = ':10';
  my $crit = ':5';
  if ($self->{dskMinPercent} >= 0) {
    $warn = $self->{dskMinPercent}.':';
    $crit = $warn;
  } elsif ($self->{dskMinimum} >= 0 && $self->{dskTotal} < 2147483647) {
    $warn = sprintf '%.2f:', 100 * $self->{dskMinimum} / $self->{dskTotal};
    $crit = $warn;
  }
  $self->set_thresholds(
      metric => sprintf('%s_free_pct', $self->{dskPath}),
      warning => $warn, critical => $crit);
  # send info
  $self->add_info(sprintf 'disk %s has %.2f%% free space left%s',
      $self->{dskPath},
      $free,
      $self->{dskErrorFlag} eq 'error'
          ? sprintf ' (%s)', $self->{dskErrorMsg}
          : '');
  # set error level if needed
  if ($self->{dskErrorFlag} eq 'error') {
    $self->add_message(Monitoring::GLPlugin::CRITICAL);
  } else {
    $self->add_message($self->check_thresholds(
        metric => sprintf('%s_free_pct', $self->{dskPath}),
        value => $free));
  }
  $self->add_perfdata(
      label => sprintf('%s_free_pct', $self->{dskPath}),
      value => $free,
      uom => '%',
  );
}

