package Classes::Cisco::IOS::Component::ConfigSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my $self = shift;
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
  my $self = shift;
  my $info;
  my $runChangedMarginAfterReload = 60;
  $self->add_info('checking config');
  if ($self->check_messages()) {
    return;
  }
  # ccmHistoryRunningLastChanged
  # ccmHistoryRunningLastSaved - saving is ANY write (local/remote storage, terminal)
  # ccmHistoryStartupLastChanged 
  $self->set_thresholds(warning => 3600, critical => 3600*24);

  # How much is ccmHistoryRunningLastChanged ahead of ccmHistoryStartupLastChanged
  # the running config could have been saved for backup purposes.
  # The saved config can still be identical to the running config.

  my $runningChangedDuration = time - $self->{ccmHistoryRunningLastChanged};
  my $startupChangedDuration = time - $self->{ccmHistoryStartupLastChanged};

  # If running config has changed after the startup config
  if ($runningChangedDuration < $startupChangedDuration) {
    # If running config has changed since boot (with 60 second margin)
    # The margin is use because after a reload the running config is ahead of the startup config by 20-40 seconds
    if (($runningChangedDuration + $runChangedMarginAfterReload) < $self->uptime()) {
      my $unsaved_since = $runningChangedDuration;
      my $errorlevel = $self->check_thresholds($unsaved_since);

      if ($errorlevel != OK && defined $self->opts->mitigation()) {
        $errorlevel = $self->opts->mitigation();
      }

      $self->add_info(sprintf "saved running config is ahead of startup config since %d minutes. device will boot with a config different from the one which was last saved",
          $unsaved_since / 60);

      $self->add_message($errorlevel);
    } else {
      $self->add_info(sprintf("running config has not changed since reload (using a %d second margin)", $runChangedMarginAfterReload));
    }
  } else {
    $self->add_info("saved config is up to date");
  }
}

sub dump {
  my $self = shift;
  printf "[CONFIG]\n";
  foreach (qw(ccmHistoryRunningLastChanged ccmHistoryRunningLastSaved
      ccmHistoryStartupLastChanged)) {
    printf "%s: %s (%s)\n", $_, $self->{$_}, scalar localtime $self->{$_};
  }
}

