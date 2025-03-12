package CheckNwcHealth::PaloAlto::Component::SecuritySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('PAN-COMMON-MIB', (qw(
      panSysAppVersion panSysAvVersion panSysThreatVersion
      panSysWildfireVersion)));
  # schars
  my $now = time;
  $self->{now_versions} = {
      panSysAvVersion => {
          version => $self->{panSysAvVersion} ?
              $self->{panSysAvVersion} : "unknown",
          changed => $now,
      },
      panSysThreatVersion => {
          version => $self->{panSysThreatVersion} ?
              $self->{panSysThreatVersion} : "unknown",
          changed => $now,
      },
      panSysWildfireVersion => {
          version => $self->{panSysWildfireVersion} ?
              $self->{panSysWildfireVersion} : "unknown",
          changed => $now,
      },
  };
  $self->{old_versions} = $self->load_state(name => "versions") || $self->{now_versions};
  foreach my $software (qw(panSysAvVersion panSysThreatVersion panSysWildfireVersion)) {
    if ($self->{now_versions}->{$software}->{version} eq "unknown") {
      # keep the old time
    } elsif ($self->{old_versions}->{$software}->{version} ne
        $self->{now_versions}->{$software}->{version}) {
      $self->{now_versions}->{$software}->{changed} = time;
    } else {
      $self->{now_versions}->{$software}->{changed} =
          $self->{old_versions}->{$software}->{changed};
    }
    $self->{now_versions}->{$software}->{age} = $now -
        $self->{now_versions}->{$software}->{changed};
  }
  $self->save_state(name => "versions", save => $self->{now_versions});
  $self->override_opt("units", "hours") if ! $self->opts->units;
}

sub check {
  my ($self) = @_;
  my $now = time;
  foreach my $software (qw(panSysAvVersion panSysThreatVersion panSysWildfireVersion)) {
    $self->add_info(sprintf "%s %s was updated %s ago", $software,
        $self->{now_versions}->{$software}->{version},
        $self->human_timeticks($self->{now_versions}->{$software}->{age}));
    my $age = $self->{now_versions}->{$software}->{age};
    my $unit = $self->opts->units;
    my $warning; my $critical;
    if ($unit eq 'hours' || $unit eq 'hour' || $unit eq 'h') {
      $age /= 3600;
      $warning = 36;
      $critical = 48;
    } elsif ($unit eq 'days' || $unit eq 'day' || $unit eq 'd') {
      $age /= 86400;
      $warning = 1.5;
      $critical = 2;
    }
    $self->set_thresholds(
        metric => (lc $software)."_age_".$self->opts->units,
        warning => $warning,
        critical => $critical,
    );
    $self->add_message($self->check_thresholds(
        metric => (lc $software)."_age_".$self->opts->units,
        value => $age,
        places => 2,
    ));
    $self->add_perfdata(
        label => (lc $software)."_age_".$self->opts->units,
        value => $age,
    );
  }
}


