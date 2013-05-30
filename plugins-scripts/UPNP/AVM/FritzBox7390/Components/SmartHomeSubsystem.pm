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
  } elsif ($self->mode =~ /smarthome::device::status/) {
    $self->update_device_cache(0);
    my @indices = $self->get_device_indices();
printf "indices:%s\n", Data::Dumper::Dumper(\@indices);
    foreach my $id (map {$_->[0]} @indices) {
      my $html = $self->http_get(
          sprintf '/net/home_auto_energy_view.lua?device=%d&sub_tab=10', $id);
#printf "%s\n", $html;
if ($html =~ /0024498/) {
 printf "i gounf ain\n";
my $x = '
<h4>FRITZ!-Aktor</h4><div class="formular"><label style="width:250px;" for="uiULEDeviceUleID" id="LabeluiULEDeviceUleID" >Modell</label><span class="output" style="width: 254px;"><nobr>FRITZ!DECT 200</nobr></span></div><div class="formular"><label style="width:250px;" for="uiULEDeviceUleID" id="LabeluiULEDeviceUleID" >Aktor Identifikationsnummer (AIN)</label><span class="output" style="width: 254px;"><nobr>08441 0044448</nobr></span></div><div class="formular" id="uiShow_Description"><label style="width:250px;" for="uiULEDeviceName" id="LabeluiULEDeviceName" >Name</label><span class="output" style="width: 254px;"><nobr>FRITZ!DECT 200 #1 WZ</nobr></span></div><div class="formular" id="uiShow_Connection"><label style="width:250px;" for="uiULEDeviceConnectState" id="LabeluiULEDeviceConnectState" >Verbindungszustand zur FRITZ!Box</label><nobr><img id="uiDeviceConnectState_16" src="/css/default/images/led_green.gif"  title="Verbunden" style="vertical-align: middle;"></nobr><span id="uiDeviceConnectStateText_"16 class="" style="padding: 0px 100px 0px 5px;vertical-align: middle;">Verbunden</span><span class="" style="padding-right: 20px;vertical-align: middle;">Schaltzustand der Steckdose</span><nobr><img id="uiDeviceSwitchState_16" src="/css/default/images/led_green.gif"  title="an" style="vertical-align: middle;"></nobr><span id="uiDeviceSwitchStateText_16" class="" style="padding-left: 5px;vertical-align: middle;">an</span></div><hr><h4>Energieanzeige für "FRITZ!DECT 200 #1 WZ"</h4>
';
# /net/home_auto_query.lua?command=OutletStates&id=id
# /net/home_auto_query.lua?command=EnergyStats_10&id=id
printf "my id is %d\n", $id;
      $html = $self->http_get(
          sprintf '/net/home_auto_query.lua?id=%d&command=OutletStates', $id);
printf "%s\n", $html;
      $html = $self->http_get(
          sprintf '/net/home_auto_query.lua?id=%d&command=EnergyStats_10&xhr=1&t%d=nocache', $id, time);
printf "%s\n", $html;
}

    }
    #push(@{$self->{smart_home_devices}},
    #    UPNP::AVM::FritzBox7390::Component::SmartHome::Device->new(%tmp_device));
  }
printf "root:%s\n", Data::Dumper::Dumper($self->{smart_home_devices});
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


package UPNP::AVM::FritzBox7390::Component::SmartHome::Device;

our @ISA = qw(UPNP::AVM::FritzBox7390::Component::SmartHome);

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
printf "och %s\n", Data::Dumper::Dumper(\%params);
  foreach my $param (qw(id on manual connected ain name)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
}
