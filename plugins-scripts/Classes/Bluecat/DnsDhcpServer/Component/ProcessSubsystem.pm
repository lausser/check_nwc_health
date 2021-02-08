package Classes::Bluecat::DnsDhcpServer::Component::ProcessSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('BCN-DNS-MIB', (qw(bcnDnsSerOperState)));
  $self->get_snmp_objects('BCN-DHCPV4-MIB', (qw(bcnDhcpv4SerOperState)));
}

sub check {
  my ($self) = @_;
  if ($self->{bcnDnsSerOperState}) {
    $self->add_info(sprintf "dns service is %s", $self->{bcnDnsSerOperState});
    $self->add_ok() if $self->{bcnDnsSerOperState} eq "running";
    $self->add_critical() if $self->{bcnDnsSerOperState} eq "notRunning";
    $self->add_warning() if $self->{bcnDnsSerOperState} eq "starting";
    $self->add_warning() if $self->{bcnDnsSerOperState} eq "stopping";
    $self->add_critical() if $self->{bcnDnsSerOperState} eq "fault";
  } else {
    $self->get_snmp_objects('ADONIS-DNS-MIB', (qw(dnsDaemonRunning)));
    if (exists $self->{dnsDaemonRunning}) {
      $self->add_info(sprintf "dns service is %s",
          $self->{dnsDaemonRunning} ? "running" : "not running");
      $self->add_ok() if $self->{dnsDaemonRunning} == 0;
      $self->add_critical() if $self->{dnsDaemonRunning} == 1;
    }
  }
  if ($self->{bcnDhcpv4SerOperState}) {
    $self->add_info(sprintf "dhcp service is %s", $self->{bcnDhcpv4SerOperState});
    $self->add_ok() if $self->{bcnDhcpv4SerOperState} eq "running";
    $self->add_critical() if $self->{bcnDhcpv4SerOperState} eq "notRunning";
    $self->add_warning() if $self->{bcnDhcpv4SerOperState} eq "starting";
    $self->add_warning() if $self->{bcnDhcpv4SerOperState} eq "stopping";
    $self->add_critical() if $self->{bcnDhcpv4SerOperState} eq "fault";
  } else {
    $self->get_snmp_objects('ADONIS-DNS-MIB', (qw(dhcpDaemonRunning)));
    if (exists $self->{dhcpDaemonRunning}) {
      $self->add_info(sprintf "dhcp service is %s",
          $self->{dhcpDaemonRunning} ? "running" : "not running");
      $self->add_ok() if $self->{dhcpDaemonRunning} == 0;
      $self->add_critical() if $self->{dhcpDaemonRunning} == 1;
    }
  }
}

