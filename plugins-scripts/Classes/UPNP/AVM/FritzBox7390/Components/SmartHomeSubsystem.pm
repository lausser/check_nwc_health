package Classes::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item Classes::UPNP::AVM::FritzBox7390);
use strict;
use JSON;
use File::Slurp qw(read_file);

sub init {
  my ($self) = @_;
  if ($self->mode =~ /smarthome::device::list/) {
    $self->update_device_cache(1);
    foreach my $ain (keys %{$self->{device_cache}}) {
      my $name = $self->{device_cache}->{$ain}->{name};
      printf "%s %s\n", $ain, $name;
    }
  } elsif ($self->mode =~ /smarthome::device/) {
    $self->update_device_cache(0);
    my @indices = $self->get_device_indices();
    foreach my $ain (map {$_->[0]} @indices) {
      my %tmp_dev = (
          ain => $ain,
          name => $self->{device_cache}->{$ain}->{name},
          functionbitmask => $self->{device_cache}->{$ain}->{functionbitmask},
      );
      push(@{$self->{smart_home_devices}},
          Classes::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem::Device->new(%tmp_dev));
    }
  }
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{smart_home_devices}}) {
    $_->check();
  }
}

sub create_device_cache_file {
  my ($self) = @_;
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
  my ($self, $force) = @_;
  my $statefile = $self->create_device_cache_file();
  my $update = time - 3600;
  if ($force || ! -f $statefile || ((stat $statefile)[9]) < ($update)) {
    $self->debug('force update of device cache');
    $self->{device_cache} = {};
    my $switchlist = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getdevicelistinfos');
    $switchlist = join(",", map {
        /<device identifier="(.*?)"/;
        my $ain = $1; $ain =~ s/\s//g;
        /<name>(.*?)<\/name>/; $self->{device_cache}->{$ain}->{name} = $1;
        /functionbitmask="(.*?)"/; $self->{device_cache}->{$ain}->{functionbitmask} = $1;
       $ain;
    } ($switchlist =~ /<device.*?<\/device>/g));
    $self->save_device_cache();
  }
  $self->load_device_cache();
}

sub save_device_cache {
  my ($self) = @_;
  $self->create_statefilesdir();
  my $statefile = $self->create_device_cache_file();
  my $tmpfile = $self->statefilesdir().'/check_nwc_health_tmp_'.$$;
  my $fh = IO::File->new();
  if ($fh->open($tmpfile, "w")) {
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
    my $jsonscalar = $coder->encode($self->{device_cache});
    $fh->print($jsonscalar);
    $fh->flush();
    $fh->close();
  }
  rename $tmpfile, $statefile;
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($self->{device_cache}), $statefile);
}

sub load_device_cache {
  my ($self) = @_;
  my $statefile = $self->create_device_cache_file();
  if ( -f $statefile) {
    my $jsonscalar = read_file($statefile);
    our $VAR1;
    eval {
      my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
      $VAR1 = $coder->decode($jsonscalar);
    };
    if($@) {
      $self->debug(sprintf "json load from %s failed. fallback", $statefile);
      delete $INC{$statefile} if exists $INC{$statefile}; # else unit tests fail
      eval "$jsonscalar";
      if($@) {
        printf "FATAL: Could not load cache in perl format!\n";
        $self->debug(sprintf "fallback perl load from %s failed", $statefile);
      }
    }
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    $self->{device_cache} = $VAR1;
  }
}

sub get_device_indices {
  my ($self) = @_;
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
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem Classes::UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cometdect} = ($self->{functionbitmask} & 0b000001000000) ? 1 : 0;
  $self->{energy} = ($self->{functionbitmask} & 0b000010000000) ? 1 : 0;
  $self->{temperature} = ($self->{functionbitmask} & 0b000100000000) ? 1 : 0;
  $self->{schaltsteck} = ($self->{functionbitmask} & 0b001000000000) ? 1 : 0;
  $self->{dectrepeater} = ($self->{functionbitmask} & 0b010000000000) ? 1 : 0;
  if ($self->mode =~ /smarthome::device::status/) {
    $self->{connected} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchpresent&ain='.$self->{ain});
    $self->{switched} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchstate&ain='.$self->{ain});
    chomp $self->{connected};
    chomp $self->{switched};
  } elsif ($self->mode =~ /smarthome::device::energy/ && $self->{energy}) {
    eval {
      $self->{last_watt} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchpower&ain='.$self->{ain});
      $self->{last_watt} /= 1000;
    };
  } elsif ($self->mode =~ /smarthome::device::consumption/ && $self->{energy}) {
    eval {
      $self->{kwh} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=getswitchenergy&ain='.$self->{ain});
      $self->{kwh} /= 1000;
    };
  } elsif ($self->mode =~ /smarthome::device::temperature/ && $self->{temperature}) {
    eval {
      $self->{celsius} = $self->http_get('/webservices/homeautoswitch.lua?switchcmd=gettemperature&ain='.$self->{ain});
      $self->{celsius} /= 10;
    };
  }
}

sub check {
  my ($self) = @_;
  my $label = $self->{name};
  if ($self->mode =~ /smarthome::device::status/) {
    $self->add_info(sprintf "device %s is %sconnected and switched %s",
        $self->{name}, $self->{connected} ? "" : "not ", $self->{switched} ? "on" : "off");
    if (! $self->{connected} || ! $self->{switched}) {
      $self->add_critical();
    } else {
      $self->add_ok(sprintf "device %s ok", $self->{name});
    }
  } elsif ($self->mode =~ /smarthome::device::energy/ && $self->{energy}) {
    $self->add_info(sprintf "device %s consumes %.4f watts",
        $self->{name}, $self->{last_watt});
    $self->set_thresholds(metric => $label."_watt",
        warning => 80 / 100 * 220 * 10, critical => 90 / 100 * 220 * 10);
    $self->add_message($self->check_thresholds(
        metric => $label."_watt", value => $self->{last_watt}));
    $self->add_perfdata(
        label => $label."_watt",
        value => $self->{last_watt},
    );
  } elsif ($self->mode =~ /smarthome::device::consumption/ && $self->{energy}) {
    $self->add_info(sprintf "device %s consumed %.4f kwh",
        $self->{name}, $self->{kwh});
    $self->set_thresholds(metric => $label."_kwh",
        warning => 1000, critical => 1000);
    $self->add_message($self->check_thresholds(
        metric => $label."_kwh", value => $self->{kwh}));
    $self->add_perfdata(
        label => $label."_kwh",
        value => $self->{kwh},
    );
  } elsif ($self->mode =~ /smarthome::device::temperature/ && $self->{temperature}) {
    $self->add_info(sprintf "device %s temperature is %.4f C",
        $self->{name}, $self->{celsius});
    $self->set_thresholds(metric => $label."_temperature",
        warning => 40, critical => 50);
    $self->add_message($self->check_thresholds(
        metric => $label."_temperature", value => $self->{celsius}));
    $self->add_perfdata(
        label => $label."_temperature",
        value => $self->{celsius},
    );
  }
}
