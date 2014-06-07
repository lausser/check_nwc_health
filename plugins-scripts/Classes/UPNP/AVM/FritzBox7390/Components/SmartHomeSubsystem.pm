package Classes::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item Classes::UPNP::AVM::FritzBox7390);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /smarthome::device::list/) {
    $self->update_device_cache(1);
    foreach my $ain (keys %{$self->{device_cache}}) {
      my $name = $self->{device_cache}->{$ain}->{name};
      printf "%02d %s\n", $ain, $name;
    }
  } elsif ($self->mode =~ /smarthome::device/) {
    $self->update_device_cache(0);
    my @indices = $self->get_device_indices();
    foreach my $ain (map {$_->[0]} @indices) {
      my %tmp_dev = (ain => $ain, name => $self->{device_cache}->{$ain}->{name});
      push(@{$self->{smart_home_devices}},
          Classes::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem::Device->new(%tmp_dev));
    }
  }
}

sub check {
  my $self = shift;
  foreach (@{$self->{smart_home_devices}}) {
    $_->check();
  }
}

sub create_device_cache_file {
  my $self = shift;
  my $extension = "";
  if ($self->opts->community) {
    $extension .= Digest::MD5::md5_hex($self->opts->community);
  }
  $extension =~ s/\//_/g;
  $extension =~ s/\(/_/g;
  $extension =~ s/\)/_/g;
  $extension =~ s/\*/_/g;
  $extension =~ s/\s/_/g;
  return sprintf "%s/%s_interface_cache_%s", $self->statefilesdir(),
      $self->opts->hostname, lc $extension;
}

sub update_device_cache {
  my $self = shift;
  my $force = shift;
  my $statefile = $self->create_device_cache_file();
  my $update = time - 3600;
  if ($force || ! -f $statefile || ((stat $statefile)[9]) < ($update)) {
    $self->debug('force update of device cache');
    $self->{device_cache} = {};
    my $switchlist = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchlist');
    my @ains = split(",", $switchlist);
    foreach my $ain (@ains) {
      chomp $ain;
      my $name = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchname&ain='.$ain);
      chomp $name;
      $self->{device_cache}->{$ain}->{name} = $name;
    }
    $self->save_device_cache();
  }
  $self->load_device_cache();
}

sub save_device_cache {
  my $self = shift;
  $self->create_statefilesdir();
  my $statefile = $self->create_device_cache_file();
  my $tmpfile = $self->statefilesdir().'/check_nwc_health_tmp_'.$$;
  my $fh = IO::File->new();
  $fh->open(">$tmpfile");
  $fh->print(Data::Dumper::Dumper($self->{device_cache}));
  $fh->flush();
  $fh->close();
  my $ren = rename $tmpfile, $statefile;
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($self->{device_cache}), $statefile);
}

sub load_device_cache {
  my $self = shift;
  my $statefile = $self->create_device_cache_file();
  if ( -f $statefile) {
    our $VAR1;
    eval {
      require $statefile;
    };
    if($@) {
      printf "rumms\n";
    }
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    $self->{device_cache} = $VAR1;
    eval {
      foreach (keys %{$self->{device_cache}}) {
        /^\d+$/ || die "newrelease";
      }
    };
    if($@) {
      $self->{device_cache} = {};
      unlink $statefile;
      delete $INC{$statefile};
      $self->update_device_cache(1);
    }
  }
}

sub get_device_indices {
  my $self = shift;
  my @indices = ();
  foreach my $id (keys %{$self->{device_cache}}) {
    my $name = $self->{device_cache}->{$id}->{name};
    if ($self->opts->name) {
      if ($self->opts->regexp) {
        my $pattern = $self->opts->name;
        if ($name =~ /$pattern/i) {
          push(@indices, [$id]);
        }
      } else {
        if ($self->opts->name =~ /^\d+$/) {
          if ($id == 1 * $self->opts->name) {
            push(@indices, [1 * $self->opts->name]);
          }
        } else {
          if (lc $name eq lc $self->opts->name) {
            push(@indices, [$id]);
          }
        }
      }
    } else {
      push(@indices, [$id]);
    }
  }
  return @indices;
}


package Classes::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem::Device;
our @ISA = qw(GLPlugin::SNMP::TableItem Classes::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem);
use strict;

sub finish {
  my $self = shift;
  if ($self->mode =~ /smarthome::device::status/) {
    $self->{connected} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchpresent&ain='.$self->{ain});
    $self->{switched} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchstate&ain='.$self->{ain});
    chomp $self->{connected};
    chomp $self->{switched};
  } elsif ($self->mode =~ /smarthome::device::energy/) {
    eval {
      $self->{last_watt} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchpower&ain='.$self->{ain});
      $self->{last_watt} /= 1000;
    };
  } elsif ($self->mode =~ /smarthome::device::consumption/) {
    eval {
      $self->{kwh} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchenergy&ain='.$self->{ain});
      $self->{kwh} /= 1000;
    };
  }
}

sub check {
  my $self = shift;
  if ($self->mode =~ /smarthome::device::status/) {
    $self->add_info(sprintf "device %s is %sconnected and switched %s",
        $self->{name}, $self->{connected} ? "" : "not ", $self->{switched} ? "on" : "off");
    if (! $self->{connected} || ! $self->{switched}) {
      $self->add_critical();
    } else {
      $self->add_ok(sprintf "device %s ok", $self->{name});
    }
  } elsif ($self->mode =~ /smarthome::device::energy/) {
    $self->add_info(sprintf "device %s consumes %.4f watts",
        $self->{name}, $self->{last_watt});
    $self->set_thresholds(
        warning => 80 / 100 * 220 * 10, 
        critical => 90 / 100 * 220 * 10);
    $self->add_message($self->check_thresholds($self->{last_watt}));
    $self->add_perfdata(
        label => 'watt',
        value => $self->{last_watt},
    );
  } elsif ($self->mode =~ /smarthome::device::consumption/) {
    $self->add_info(sprintf "device %s consumed %.4f kwh",
        $self->{name}, $self->{kwh});
    $self->set_thresholds(warning => 1000, critical => 1000);
    $self->add_message($self->check_thresholds($self->{kwh}));
    $self->add_perfdata(
        label => 'kwh',
        value => $self->{kwh},
    );
  }
}
