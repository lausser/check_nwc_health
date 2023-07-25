package CheckNwcHealth::Cisco::IOS::Component::ConfigSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-CONFIG-MAN-MIB', (qw(
      ccmHistoryRunningLastChanged ccmHistoryRunningLastSaved
      ccmHistoryStartupLastChanged)));
  foreach ((qw(ccmHistoryRunningLastChanged ccmHistoryRunningLastSaved
      ccmHistoryStartupLastChanged))) {
    if (! defined $self->{$_}) {
      $self->add_unknown(sprintf "%s is not defined", $_);
    }
    $self->{$_} = time - $self->uptime() + $self->timeticks($self->{$_});
  }
}

sub check {
  my ($self) = @_;
  my $info;
  my $runningChangedMarginAfterReload = 300;
  $self->add_info('checking config');
  if ($self->check_messages()) {
    return;
  }

  # Set default thresholds: Warning 1 hour, Critical 24 hours
  $self->set_thresholds(warning => 3600, critical => 3600*24);

  # How much is ccmHistoryRunningLastChanged ahead of ccmHistoryStartupLastChanged
  # Note: the saved config could still be identical to the running config.

  # ccmHistoryRunningLastChanged
  # ccmHistoryRunningLastSaved - saving is ANY write (local/remote storage, terminal)
  # ccmHistoryStartupLastChanged 
  my $runningUnchangedDuration = time - $self->{ccmHistoryRunningLastChanged};
  my $startupUnchangedDuration = time - $self->{ccmHistoryStartupLastChanged};

  # If running config has been changed after the startup config
  if ($runningUnchangedDuration < $startupUnchangedDuration) {
    # After a reload the running config is reported to be ahead of the startup config by a few seconds to possibly
    # a few minutes, while neither has been changed. Therefor a reload-margin is used.
    # If running config is reported to have changed within the (5 minute) margin since the last reload
    if (($runningUnchangedDuration + $runningChangedMarginAfterReload) > $self->uptime()) {
      $self->add_ok(sprintf("running config has not changed since reload (using a %d second margin)",
          $runningChangedMarginAfterReload));
    } else {
      # Running config is unsaved since $runningUnchangedDuration
      my $errorlevel = $self->check_thresholds($runningUnchangedDuration);

      if ($errorlevel != OK && defined $self->opts->mitigation()) {
        $errorlevel = $self->opts->mitigation();
      }

      $self->add_info(sprintf "running config is ahead of startup config since %d minutes. changes will be lost in case of a reboot",
          $runningUnchangedDuration / 60);
      $self->add_message($errorlevel);
    }
  } else {
    $self->add_ok("saved config is up to date");
  }
}

sub dump {
  my ($self) = @_;
  printf "[CONFIG]\n";
  foreach (qw(ccmHistoryRunningLastChanged ccmHistoryRunningLastSaved ccmHistoryStartupLastChanged)) {
    printf "%s: %s (%s)\n", $_, $self->{$_}, scalar localtime $self->{$_};
  }
}

