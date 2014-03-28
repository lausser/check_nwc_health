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
  # The saved config can still be identical to the saved running config.
  my $unsaved_since = 
      $self->{ccmHistoryRunningLastChanged} > $self->{ccmHistoryStartupLastChanged} ?
      time - $self->{ccmHistoryRunningLastChanged} : 0;
  if ($unsaved_since) {
    $self->add_info(sprintf "running config is modified and unsaved since %d minutes. your changes may be lost in case of a reboot",
        $unsaved_since / 60);
  } else {
    $self->add_info("saved config is up to date");
  }
  if ($unsaved_since) {
    my $errorlevel = $self->check_thresholds($unsaved_since);
    if ($errorlevel != OK && defined $self->opts->mitigation()) {
      $errorlevel = $self->opts->mitigation();
    }
    $self->add_info(sprintf "saved running config is ahead of startup config since %d minutes. device will boot with a config different from the one which was last saved",
        $unsaved_since / 60);
    $self->add_message($errorlevel);
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

