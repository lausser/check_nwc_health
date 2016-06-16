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

  # use 32bit counter first
  my $avail = $self->{dskAvail};
  my $total = $self->{dskTotal};
  my $used = $self->{dskUsed};

  # support large disks if 64bit counter are present
  if (defined $self->{dskAvailHigh} && defined $self->{dskAvailLow}
      && $self->{dskAvailHigh} > 0) {
    $avail = $self->{dskAvailHigh} * 2**32 + $self->{dskAvailLow};
  }
  if (defined $self->{dskTotalHigh} && defined $self->{dskTotalLow}
      && $self->{dskTotalHigh} > 0) {
    $total = $self->{dskTotalHigh} * 2**32 + $self->{dskTotalLow};
  }
  if (defined $self->{dskUsedHigh} && defined $self->{dskUsedLow}
      && $self->{dskUsedHigh} > 0) {
    $used = $self->{dskUsedHigh} * 2**32 + $self->{dskUsedLow};
  }

  # calc free space left
  my $free = 100 * $avail / $total;

  # define + set threshold
  my $warn = '10:';
  my $crit = '5:';
  my $warn_used = int($total * 0.9);
  my $crit_used = int($total * 0.95);

  # set threshold based on snmp response
  if ($self->{dskMinPercent} >= 0) {
    $warn = sprintf '%d:', $self->{dskMinPercent};
    $crit = $warn;
    $warn_used = int($total * (1 - $self->{dskMinPercent}/100));
    $crit_used = $warn_used;
  } elsif ($self->{dskMinimum} >= 0) {
    $warn = sprintf '%f:', $self->{dskMinimum} / $total;
    $crit = $warn;
    $warn_used = $total - $self->{dskMinimum};
    $crit_used = $warn_used;
  }

  # now set the thresholds
  $self->set_thresholds(metric => sprintf('%s_free_pct', $self->{dskPath}),
      warning => $warn, critical => $crit);

  # display human readable free space message
  my $spaceleft = int($avail/1024);
  $spaceleft =~ s/(?<=\d)(?=(?:\d\d\d)+\b)/,/g;
  $self->add_info(sprintf '%s has %s MB left (%.2f%%)%s',
      $self->{dskPath}, $spaceleft, $free,
      $self->{dskErrorFlag} eq 'error'
          ? sprintf ' - %s', $self->{dskErrorMsg}
          : '');

  # raise critical error if errorflag is set
  if ($self->{dskErrorFlag} eq 'error') {
    $self->add_critical();
  } else {
    # otherwise check thresholds
    $self->add_message($self->check_thresholds(
        metric => sprintf('%s_free_pct', $self->{dskPath}),
        value => $free));
  }

  # add performance data
  $self->add_perfdata(
      label => sprintf('%s_free_pct', $self->{dskPath}),
      value => $free,
      uom => '%',
  );

  # add additional perfdata and map thresholds if they have been changed
  # via commandline arguments (just for perfdata display
  my @thresholds = $self->get_thresholds(
      metric => sprintf('%s_free_pct', $self->{dskPath}));
  if ($warn ne $thresholds[0] && $thresholds[0] =~ m/^(\d+):$/) {
    $warn_used = int($total * (1 - $1/100));
  }
  if ($crit ne $thresholds[1] && $thresholds[1] =~ m/^(\d+):$/) {
    $crit_used = int($total * (1 - $1/100));
  }
  $self->add_perfdata(
      label => sprintf('%s_used_kb', $self->{dskPath}),
      value => $used,
      uom => 'kb',
      min => 0,
      max => $total,
      warning => $warn_used,
      critical => $crit_used
  );
}

