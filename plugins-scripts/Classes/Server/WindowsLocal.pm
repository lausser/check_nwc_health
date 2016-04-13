package Server::WindowsLocal;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem('Server::WindowsLocal::Component::InterfaceSubsystem');
  }
}


package Server::WindowsLocal::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub merge_by_canonical {
  my ($self, $tmpif, $network_adapters, $network_adapter_configs) = @_;
  $tmpif->{CanonicalName} = $tmpif->{ifDescr};
  $tmpif->{CanonicalName} =~ s/[^0-9a-zA-Z]/_/g;
  $self->debug(sprintf "found interface %s", $tmpif->{CanonicalName});
  if (! exists $network_adapter_configs->{$tmpif->{CanonicalName}}) {
    foreach (keys %{$network_adapters}) {
printf "= %s\n  %s\n", substr($tmpif->{CanonicalName}, 0, length($_)), $_;
      if (substr($tmpif->{CanonicalName}, 0, length($_)) eq $_) {
        $tmpif->{CanonicalName} = $_;
printf "dong\n";
        last;
      }
    }
  }
  if (exists $network_adapters->{$tmpif->{CanonicalName}}) {
    map {
      $tmpif->{$_} = $network_adapters->{$tmpif->{CanonicalName}}->{$_}
    } (qw(Index NetConnectionStatus NetEnabled));
    if (exists $network_adapter_configs->{$tmpif->{Index}}) {
      map {
        $tmpif->{$_} = $network_adapter_configs->{$tmpif->{Index}}->{$_}
      } (qw(InterfaceIndex));
    }
  }
}

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
    $self->debug("select Description, DeviceID, Index, MACAddress, MaxSpeed, NetConnectionID, NetConnectionStatus, NetEnabled, Speed, Status, StatusInfo from Win32_NetworkAdapter");
    $sth->execute();
    map {
      my $copy = {};
      my $orig = $_;
      map { $copy->{$_} = $orig->{$_} } (qw(Description DeviceID Index MACAddress MaxSpeed Name NetConnectionID NetConnectionStatus NetEnabled Speed Status StatusInfo));
      $copy->{CanonicalName} = unpack("Z*", $_->{Name});
      $copy->{CanonicalName} =~ s/[^0-9a-zA-Z]/_/g;
      $network_adapters->{$copy->{CanonicalName}} = $copy;
printf "network_adapters %s\n", Data::Dumper::Dumper($copy);
printf "network_adapters %s     %d\n", $copy->{CanonicalName}, $copy->{Index};
    } map {
      $_->[0];
    } @{$sth->fetchall_arrayref()};
    $sth->finish();
    $sth = $dbh->prepare("select * from Win32_NetworkAdapterConfiguration");
    # Description, InterfaceIndex, IPAddress, IPEndbled, IPSubnet, MTU
    $self->debug("select * from Win32_NetworkAdapterConfiguration");
    $sth->execute();
    map {
      my $copy = {};
      my $orig = $_;
      map { $copy->{$_} = $orig->{$_} } (qw(Description Index InterfaceIndex MACAddress MTU));
      $network_adapter_configs->{$copy->{Index}} = $copy;
    } map {
      $_->[0];
    } @{$sth->fetchall_arrayref()};
$self->debug("finish");
    $sth->finish();
    $sth = $dbh->prepare("select * from Win32_PerfRawData_Tcpip_NetworkInterface");
    $self->debug("select * from Win32_PerfRawData_Tcpip_NetworkInterface");
    $sth->execute();
    my $index = 0;
    while (my $member_arr = $sth->fetchrow_arrayref()) {
      my $member = $member_arr->[0];
      my $tmpif = {
        ifDescr => unpack("Z*", $member->{Name}),
        ifIndex => $index++,
      };
      $self->merge_by_canonical($tmpif, $network_adapters, $network_adapter_configs);
      push(@{$self->{interfaces}},
        Server::WindowsLocal::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
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
          Server::WindowsLocal::Component::InterfaceSubsystem::Interface->new(%{$tmpif}));
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


package Server::WindowsLocal::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;

sub finish {
  my $self = shift;
  # NetEnabled 1=admin up
  # NetConnectionStatus Disconnected (0)Connecting (1)Connected (2)Disconnecting (3)Hardware Not Present (4)Hardware Disabled (5)Hardware Malfunction (6)Media Disconnected (7)Authenticating (8)Authentication Succeeded (9)Authentication Failed (10)Invalid Address (11)Credentials Required (12)Other (13–65535)
  $self->SUPER::finish();
}

