package Classes::Bluecat::DnsDhcpServer::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ADONIS-DNS-MIB', qw(haServiceRunning));
  if ($self->mode =~ /device::ha::status/) {
  } elsif ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_objects('ADONIS-DNS-MIB', qw(haServiceNodeType));
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::status/) {
    if ($self->{haServiceRunning} == 0) {
      $self->add_critical_mitigation("HA service is not running");
    } else {
      $self->add_ok("HA service is running");
    }
  } elsif ($self->mode =~ /device::ha::role/) {
    $self->{haServiceNodeType} = $self->{haServiceNodeType} == 1 ?
        "active" : "passive";
    if ($self->{haServiceRunning} == 1) {
      $self->add_info(sprintf 'ha node type is %s', $self->{haServiceNodeType});
      if ($self->opts->role() ne $self->{haServiceNodeType}) {
        $self->add_critical_mitigation();
      } else {
        $self->add_ok();
      }
    } else {
      $self->add_critical_mitigation("HA service is not running");
    }
  }
}

