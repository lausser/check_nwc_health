package CheckNwcHealth::Barracuda::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_tables('PHION-MIB', [
      ['services', 'serverServicesTable', 'CheckNwcHealth::Barracuda::Component::HaSubsystem::Service'],
    ]);
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  #printf "info %s\n", $self->get_info();
  $self->add_ok(sprintf "%s node", $self->opts->role());
  my $num_services = scalar(@{$self->{services}});
  my $num_up_services = scalar(grep { $_->{serverServiceState} eq "started" } @{$self->{services}});
  if (! $num_services) {
    $self->add_unknown(sprintf "no failover service found. (only %s)",
        join(", ", map { $_->{serverServiceName} } @{$self->{services}}));
  }
}


package CheckNwcHealth::Barracuda::Component::HaSubsystem::Service;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  my $type_signature = $self->{serverServiceName};
  if ($self->{serverServiceName} =~ /^\w+[-_:\/](\w+)/) {
    $type_signature = $1;
  }
  if ($type_signature =~ /FW/) {
    $self->{serverServiceType} = "FW";
  } elsif ($type_signature =~ /VPN/) {
    $self->{serverServiceType} = "VPN";
  } else {
    $self->{serverServiceType} = "DHCP";
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
    $self->add_info(sprintf "service %s is %s",
        $self->{serverServiceName},
        $self->{serverServiceState});
    if ($self->opts->role() eq "active") {
      if ($self->{serverServiceState} eq "started") {
        $self->add_ok();
      } elsif ($self->{serverServiceState} eq "stopped") {
        $self->add_warning();
      } elsif ($self->{serverServiceState} eq "blocked") {
        $self->add_critical();
      } else {
        $self->add_unknown();
      }
    } else {
      if ($self->{serverServiceState} eq "stopped") {
        $self->add_ok();
      } elsif ($self->{serverServiceState} eq "started") {
        $self->add_warning();
      } elsif ($self->{serverServiceState} eq "blocked") {
        $self->add_critical();
      } else {
        $self->add_unknown();
      }
    }
  }
}

__END__
Irgendwann 2019....der einzige Unterschied zwischen zwei Clusterpartnern war
die Liste der serverServiceState (bei gleichen serverServiceName)
Sonst nix, absolut nix, beide snmpwalks gleich.
Die Services hiessen SE1FWEXT, SE1FWEXT_FWEXT und SE1FWEXT_VPNEXT
Nach vielem Hin und Her geht die Frage an den Hersteller, wie man den Cluster
ueberwacht. Antwort:

-	Cluster OK Grün
o	fwext-node1 gibt folgende Werte zurück: Server SE1FWEXT= 1:up    Service SE1FWEXT_FWEXT=1:up   Service SE1FWEXT_VPNEXT=1:up
o	fwext-node2 gibt folgende Werte zurück: Server SE1FWEXT= 1:up    Service SE1FWEXT_FWEXT= stopped  Service SE1FWEXT_VPNEXT=stopped

-	Cluster Warning Gelb
o	fwext-node1 gibt folgende Werte zurück: Server SE1FWEXT= 1:up    Service SE1FWEXT_FWEXT= stopped oder 0:down   Service SE1FWEXT_VPNEXT= stopped oder 0:down
o	fwext-node2 gibt folgende Werte zurück: Server SE1FWEXT= 1:up    Service SE1FWEXT_FWEXT=1:up   Service SE1FWEXT_VPNEXT=1:up
o	Oder:
o	fwext-node1 gibt folgende Werte zurück: Server SE1FWEXT= 1:up    Service SE1FWEXT_FWEXT=1:up   Service SE1FWEXT_VPNEXT=1:up
o	fwext-node2 gibt folgende Werte zurück: Server SE1FWEXT= 1:up    Service SE1FWEXT_FWEXT=0:down   Service SE1FWEXT_VPNEXT=0:down

-	Cluster Critical Rot
o	fwext-node1 gibt folgende Werte zurück: Server SE1FWEXT= 0:down oder 2:block
o	Oder:
o	fwext-node2 gibt folgende Werte zurück: Server SE1FWEXT= 0:down oder 2:block

Also diese drei Services hart ins Plugin eingebaut.

Irgendwann 2021 sollen weitere Cluster dazukommen. Nur, jetzt heissen die
Services z.b. FZFW009_DH009, FZFW009_FW009 und FZFW009_VPN009.
Schaut so aus, als koenten die Servernamen voellig willkuerlich vergeben werden.
Bleibt nichts anderes uebrig, als nach FW und VPN zu suchen und nach Spuren von DHCP (oder weder FW noch VPN).
