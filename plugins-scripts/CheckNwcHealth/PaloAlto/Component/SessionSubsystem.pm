package CheckNwcHealth::PaloAlto::Component::SessionSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

# On a Palo Alto Networks firewall, a session is defined by two uni-directional flows each uniquely identified by a 6-tuple key: source-address, destination-address, source-port, destination-port, protocol, and security-zone.
sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::session::usage/) {
    $self->get_snmp_objects('PAN-COMMON-MIB', (qw(
      panSessionUtilization)));
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking sessions');
  $self->add_info(sprintf 'session table usage is %.2f%%',
      $self->{panSessionUtilization},
  );
  $self->set_thresholds(
      metric => 'session_usage',
      warning => 80, critical => 90
  );
  $self->add_message(
      $self->check_thresholds(
          metric => 'session_usage',
          value => $self->{panSessionUtilization},
      )
  );
  $self->add_perfdata(
      label => 'session_usage',
      value => $self->{panSessionUtilization},
      uom => '%',
  );
}

