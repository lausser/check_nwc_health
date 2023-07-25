package CheckNwcHealth::Fortigate::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self, %params) = @_;
  my $type = 0;
  $self->get_snmp_objects('FORTINET-FORTIGATE-MIB', (qw(
      fgSysSesCount)));
}

sub check {
  my ($self) = @_;
  my $errorfound = 0;
  $self->add_info('checking vpn sessions');
  $self->add_info(sprintf '%u vpn sessions', $self->{fgSysSesCount});
  $self->set_thresholds(warning => 25000, critical => 50000);
  $self->add_message($self->check_thresholds($self->{fgSysSesCount}));
  $self->add_perfdata(
      label => 'vpn_session_count',
      value => $self->{fgSysSesCount},
  );
}

