package Classes::CiscoIOS::Component::ConfigSubsystem;
our @ISA = qw(Classes::CiscoIOS);
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
  my %params = @_;
  foreach (qw(ccmHistoryRunningLastChanged ccmHistoryRunningLastSaved
      ccmHistoryStartupLastChanged)) {
    $self->{$_} = $self->get_snmp_object('CISCO-CONFIG-MAN-MIB', $_);
    $self->{$_} = time - $self->uptime() + $self->timeticks($self->{$_});
  }
}

sub check {
  my $self = shift;
  my $info;
  $self->add_info('checking config');
  # ccmHistoryRunningLastChanged
  # ccmHistoryRunningLastSaved - saving is ANY write (local/remote storage, terminal)
  # ccmHistoryStartupLastChanged 
  $self->set_thresholds(warning => 3600, critical => 3600*24);

  # ??? 
  # The Running config is stored in RAM, so it's lost either way if changed,
  # unless copied to the startup config (which is saved in NVRAM.)
  # Don't understand the use of unsaved_since (using Cisco's like 2901, 3750)
  # ???

  # how much is ccmHistoryRunningLastChanged ahead of ccmHistoryRunningLastSaved
  # the current running config is definitively lost in case of an outage
  my $unsaved_since =
      $self->{ccmHistoryRunningLastChanged} > $self->{ccmHistoryRunningLastSaved} ?
      time - $self->{ccmHistoryRunningLastChanged} : 0;

  # How much is ccmHistoryRunningLastChanged ahead of ccmHistoryStartupLastChanged
  # the running config could have been saved for backup purposes.
  # The saved config can still be identical to the saved running config.
  # If there are regular backups of the running config and no one messes
  # with the latter without flushing it to the startup config, then i recommend
  # to use --mitigation ok. This can be in an environment, where there is
  # a specific day of the week reserved for maintenance and admins are forced
  # to save their modifications to the startup-config.
  my $unsynced_since = 
      $self->{ccmHistoryRunningLastChanged} > $self->{ccmHistoryStartupLastChanged} ?
      time - $self->{ccmHistoryRunningLastChanged} : 0;
  if ($unsaved_since) {
    $info = sprintf "running config is modified and unsaved since %d minutes. your changes may be lost in case of a reboot",
        $unsaved_since / 60;
  } else {
    $info = "saved config is up to date";
  }
  $self->add_message($self->check_thresholds($unsaved_since), $info);
  if ($unsynced_since) {
    my $errorlevel = $self->check_thresholds($unsynced_since);
    if ($errorlevel != OK && defined $self->opts->mitigation()) {
      $errorlevel = $self->opts->mitigation();
    }

    $info = sprintf "saved running config is ahead of startup config since %d minutes. device will boot with a config different from the one which was last saved",
        $unsynced_since / 60;
    $self->add_message($errorlevel, $info);
  }
}

sub dump {
  my $self = shift;
  printf "[CONFIG]\n";
  foreach (qw(ccmHistoryRunningLastChanged ccmHistoryRunningLastSaved
      ccmHistoryStartupLastChanged)) {
    printf "%s: %s %s\n", $_, $self->{$_}, scalar localtime $self->{$_};
  }
}

