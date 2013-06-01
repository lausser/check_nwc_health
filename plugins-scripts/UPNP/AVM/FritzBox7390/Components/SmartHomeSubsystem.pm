package UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem;

our @ISA = qw(UPNP::AVM::FritzBox7390);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
    smart_home_devices => [],
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  if ($self->mode =~ /smarthome::device::list/) {
    $self->update_device_cache(1);
    foreach my $id (keys %{$self->{device_cache}}) {
      my $name = $self->{device_cache}->{$id}->{name};
      printf "%02d %s\n", $id, $name;
    }
  } elsif ($self->mode =~ /smarthome::device/) {
    $self->update_device_cache(0);
    my @indices = $self->get_device_indices();
    foreach my $id (map {$_->[0]} @indices) {
      my %tmp_dev = (id => $id, name => $self->{device_cache}->{$id}->{name});
      push(@{$self->{smart_home_devices}},
          UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem::Device->new(%tmp_dev));
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
  return sprintf "%s/%s_interface_cache_%s", $NWC::Device::statefilesdir,
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
    my $html = $self->http_get('/net/home_auto_overview.lua');
    my $tree  = HTML::TreeBuilder->new_from_content(Encode::decode_utf8($html));
    my $table = $tree->look_down(_tag => 'table', id => 'tHAdevices');
    my @rows = @{$table->content()};
    foreach my $row (@rows[1..$#rows]) {
      # skip the tr/th
      my %tmp_device = ();
      foreach (map {$_->as_HTML()} @{$row->content()}) {
        if (/class="c1".*img id=".*?(\d+)".*title="(.*?)"/) {
          $tmp_device{id} = $1;
        } elsif (/class="c2".*title="(.*?)"/) {
          $tmp_device{name} = $1;
        }
      }
      $self->{device_cache}->{$tmp_device{id}}->{name} = $tmp_device{name};
    }
    $self->save_device_cache();
  }
  $self->load_device_cache();
}

sub save_device_cache {
  my $self = shift;
  $self->create_statefilesdir();
  my $statefile = $self->create_device_cache_file();
  my $tmpfile = $NWC::Device::statefilesdir.'/check_nwc_health_tmp_'.$$;
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


package UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem::Device;

our @ISA = qw(UPNP::AVM::FritzBox7390::Component::SmartHomeSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $param (qw(id model switched connected ain name)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  if ($self->mode =~ /smarthome::device::status/) {
    my $device = $self->http_get(
        sprintf '/net/home_auto_energy_view.lua?device=%d&sub_tab=10', $self->{id});
    $device =~ /Modell<.*?><nobr>(.*?)<\/nobr>/; $self->{model} = $1;
    $device =~ /\(AIN\)<.*?><nobr>(.*?)<\/nobr>/; $self->{ain} = $1;
    $device =~ /Name<.*?><nobr>(.*?)<\/nobr>/; $self->{name} = $1;
    $device =~ /<img id="uiDeviceConnectState.*?\/images\/led_(.*?)\.gif"/; $self->{connected} = $1 eq "green" ? 1 : 0;
    $device =~ /<img id="uiDeviceSwitchState.*?\/images\/led_(.*?)\.gif"/; $self->{switched} = $1 eq "green" ? 1 : 0;
  } elsif ($self->mode =~ /smarthome::device::energy/) {
    my $json = JSON->new->allow_nonref;
    my $html = $self->http_get(
        sprintf '/net/home_auto_query.lua?id=%d&command=OutletStates', $self->{id});
    my $energy = $self->http_get(
        sprintf '/net/home_auto_query.lua?id=%d&command=EnergyStats_10&xhr=1&t%d=nocache', $self->{id}, time);
    $energy = $json->decode($energy);
    my @watts = map { /value_(\d+)/; [$1, $energy->{$_}] } grep /watt_value/, keys %{$energy}; @watts = ([0, 0]) if $#watts == -1;
    $self->{last_watt} = (map { $_->[1] / 100; } sort { $a->[0] <=> $b->[0] } @watts)[0];
    my @volts = map { /value_(\d+)/; [$1, $energy->{$_}] } grep /volt_value/, keys %{$energy}; @volts = ([0, 0]) if $#volts == -1;
    $self->{last_volt} = (map { $_->[1] / 1000; } sort { $a->[0] <=> $b->[0] } @volts)[0];
    $self->{max_watt} = $energy->{EnStats_max_value} / 100;
    $self->{min_watt} = $energy->{EnStats_min_value} / 100;
  } elsif ($self->mode =~ /smarthome::device::consumption/) {
    my $html = $self->http_get(
        sprintf '/net/home_auto_energy_view.lua?device=%d&sub_tab=10', $self->{id});
    my $tree  = HTML::TreeBuilder->new_from_content(Encode::decode_utf8($html));
    my $table = $tree->look_down(_tag => 'table', id => 'tHAconsumption');
    my @rows = @{$table->content()};
    foreach (map {$_->as_HTML();} @rows[1..$#rows]) {
      if (/Pro Tag.*?>([\d,]+)<.*?>([\d,]+)<.*?>([\d,]+)</) {
        $self->{d}->{euro} = $1;
        $self->{d}->{kwh} = $2;
        $self->{d}->{kgco2} = $3;
      } elsif (/Pro Monat.*?>([\d,]+)<.*?>([\d,]+)<.*?>([\d,]+)</) {
        $self->{m}->{euro} = $1;
        $self->{m}->{kwh} = $2;
        $self->{m}->{kgco2} = $3;
      } elsif (/Pro Jahr.*?>([\d,]+)<.*?>([\d,]+)<.*?>([\d,]+)</) {
        $self->{y}->{euro} = $1;
        $self->{y}->{kwh} = $2;
        $self->{y}->{kgco2} = $3;
      }
    }
    foreach my $t (qw(d m y)) {
      foreach my $u (qw(kwh euro kgco2)) {
        $self->{$t}->{$u} =~ s/,/./g;
      }
    }
  }
}

sub check {
  my $self = shift;
  if ($self->mode =~ /smarthome::device::status/) {
    my $info = sprintf "device %s is %sconnected and switched %s",
        $self->{name}, $self->{connected} ? "" : "not ", $self->{switched} ? "on" : "off";
    $self->add_info($info);
    if (! $self->{connected} || ! $self->{switched}) {
      $self->add_message(CRITICAL, $info);
    } else {
      $self->add_message(OK, sprintf "device %s ok", $self->{name});
    }
  } elsif ($self->mode =~ /smarthome::device::energy/) {
printf "%s\n", Data::Dumper::Dumper($self);
    my $info = sprintf "device %s consumes %.2f watts at %.2f volts",
        $self->{name}, $self->{last_watt}, $self->{last_volt};
    $self->add_info($info);
    $self->set_thresholds(
        warning => 80 / 100 * 220 * 10, 
        critical => 90 / 100 * 220 * 10);
    $self->add_message($self->check_thresholds($self->{last_watt}), $info);
    $self->add_perfdata(
        label => 'watt',
        value => $self->{last_watt},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => 'watt_min',
        value => $self->{min_watt},
    );
    $self->add_perfdata(
        label => 'watt_max',
        value => $self->{max_watt},
    );
    $self->add_perfdata(
        label => 'volt',
        value => $self->{last_volt},
    );
  } elsif ($self->mode =~ /smarthome::device::consumption/) {
    my $i = 'kwh';
    my $info = '';
    $self->set_thresholds(warning => 1000, critical => 1000);
    if (! $self->opts->units || $self->opts->units eq 'kwh') {
      $i = 'kwh';
      $info = sprintf '%s consumes %.2f kwh per day', $self->{name}, $self->{d}->{kwh};
    } elsif ($self->opts->units eq 'euro') {
      $i = 'euro';
      $info = sprintf '%s costs %.2f euro per day', $self->{name}, $self->{d}->{euro};
    } elsif ($self->opts->units eq 'kgco2') {
      $i = 'kgco2';
      $info = sprintf '%s produces %.2f kg co2 per day', $self->{name}, $self->{d}->{kgco2};
    }
    $self->add_message($self->check_thresholds($self->{m}->{$i}), $info);
    foreach (qw(day)) {
      $self->add_perfdata(
          label => $i.'_'.$_,
          value => $self->{substr($_,0,1)}->{$i},
          warning => $self->{warning},
          critical => $self->{critical},
      );
    }
    foreach (qw(month year)) {
      $self->add_perfdata(
          label => $i.'_'.$_,
          value => $self->{substr($_,0,1)}->{$i},
      );
    }
  }
}
