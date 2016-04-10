package Server::Windows;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem('Server::Windows::Component::InterfaceSubsystem');
  }
}


package Server::Windows::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{interfaces} = [];
# bits per second
  if ($self->mode =~ /device::interfaces::list/) {
    my $network_adapter_configs = {};
    my $network_adapters = {};
    my $dbh = DBI->connect('dbi:WMI:');
    my $sth = $dbh->prepare("select * from Win32_NetworkAdapter");
    # AdapterType, DeviceID, MACAddress, MaxSpeed, NetConnectionStatus, StatusInfo
    $sth->execute();
    map {
      $network_adapters->{$_->{DeviceID}} = $_;
    } map {
      $_->[0];
    } @{$sth->fetchall_arrayref()};
    $sth->finish();
    $sth = $dbh->prepare("select * from Win32_NetworkAdapterConfiguration");
    # Description, InterfaceIndex, IPAddress, IPEndbled, IPSubnet, MTU
    $sth->execute();
    map {
      $network_adapter_configs->{$_->{Description}} = $_;
    } map {
      $_->[0];
    } @{$sth->fetchall_arrayref()};
    $sth->finish();
map { my $x = $_; 
 if (ref($network_adapters->{$x}) eq "SCALAR") {
 } else {
   delete $network_adapters->{$x};
  }
} keys %{$network_adapters};
map { my $x = $_; 
 if (ref($network_adapter_configs->{$x}) eq "SCALAR") {
 } else {
   delete $network_adapter_configs->{$x};
  }
} keys %{$network_adapters};
printf "%s\n", Data::Dumper::Dumper($network_adapters);
printf "%s\n", Data::Dumper::Dumper($network_adapter_configs);
    $sth = $dbh->prepare("select * from Win32_PerfRawData_Tcpip_NetworkInterface");
    $sth->execute();
    while (my $member_arr = $sth->fetchrow_arrayref()) {
      my $member = $member_arr->[0];
      my $tmpif = {
        ifDescr => $member->{Name},
      };
      if (exists $network_adapter_configs->{$member->{Name}}) {
        $tmpif->{ifIndex} = $network_adapter_configs->{$member->{Name}}->{Index};
        $tmpif->{ifMTU} = $network_adapter_configs->{$member->{Name}}->{MTU};
        if (exists $network_adapters->{$tmpif->{ifIndex}}) {
          $tmpif->{ifOperStatus} = $network_adapters->{$tmpif->{ifIndex}}->{NetConnectionStatus};
          $tmpif->{ifAdminStatus} = $network_adapters->{$tmpif->{ifIndex}}->{StatusInfo};
        }
      }
      push(@{$self->{interfaces}},
        Server::Windows::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
    }
    $sth->finish();
  } else {
    my $dbh = DBI->connect('dbi:WMI:');
    my $sth = $dbh->prepare("select * from Win32_PerfRawData_Tcpip_NetworkInterface");
    $sth->execute();
    while (my $member_arr = $sth->fetchrow_arrayref()) {
      my $i = 0;
      my $member = $member_arr->[0];
      my $name = $member->{Name};
      $name =~ s/.*\///g;
      if ($self->opts->name) {
        if ($self->opts->regexp) {
          my $pattern = $self->opts->name;
          if ($name !~ /$pattern/i) {
            next;
          }
        } elsif (lc $name ne lc $self->opts->name) {
          next;
        }
      }
      *SAVEERR = *STDERR;
      open ERR ,'>/dev/null';
      *STDERR = *ERR;
      my $tmpif = {
        ifDescr => $name,
        ifIndex => $name,
        ifSpeed => $member->{CurrentBandwidth}, # bits per second
        ifInOctets => $member->{BytesReceivedPerSec},
        ifInDiscards => $member->{PacketsReceivedDiscarded},
        ifInErrors => $member->{PacketsReceivedErrors},
        ifOutOctets => $member->{BytesSentPerSec},
        ifOutDiscards => $member->{PacketsOutboundDiscarded},
        ifOutErrors => $member->{PacketsOutboundErrors},
        ifOperStatus => 'up', # found no way to get interface status
      };
      *STDERR = *SAVEERR;
      map { 
          chomp $tmpif->{$_} if defined $tmpif->{$_}; 
          $tmpif->{$_} =~ s/\s*$//g if defined $tmpif->{$_};
      } keys %{$tmpif};
      $tmpif->{ifOperStatus} = 'down' if $tmpif->{ifOperStatus} ne 'up';
      $tmpif->{ifAdminStatus} = $tmpif->{ifOperStatus};
      if (defined $self->opts->ifspeed) {
        $tmpif->{ifSpeed} = $self->opts->ifspeed * 1024*1024;
      } else {
        $tmpif->{ifSpeed} *= 1024*1024 if defined $tmpif->{ifSpeed};
      }
      if (! defined $tmpif->{ifSpeed}) {
        $self->add_unknown(sprintf "There is no CurrentBandwidth. Use --ifspeed", $name);
      } else {
        push(@{$self->{interfaces}},
          Server::Windows::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
      }
    }
    $sth->finish();
    $sth = $dbh->prepare("select * from Win32_NetworkAdapter");
    $sth->execute();
    while (my $member_arr = $sth->fetchrow_arrayref()) {
    }
    $sth->finish();
    $sth = $dbh->prepare("select * from CIM_NetworkAdapter");
    $sth->execute();
    while (my $member_arr = $sth->fetchrow_arrayref()) {
    }
    $sth->finish();
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking interfaces');
  if (scalar(@{$self->{interfaces}}) == 0) {
    $self->add_unknown('no interfaces');
    return;
  }
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (sort {$a->{ifDescr} cmp $b->{ifDescr}} @{$self->{interfaces}}) {
      $_->list();
    }
  } else {
    foreach (@{$self->{interfaces}}) {
      $_->check();
    }
  }
}


package Server::Windows::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;


