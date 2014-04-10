package Classes::AVOS::Component::ConnectionSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('BLUECOAT-AV-MIB', (qw(
      avSlowICAPConnections)));
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%d slow ICAP connections',
      $self->{avSlowICAPConnections});
  $self->set_thresholds(warning => 100, critical => 100);
  $self->add_message($self->check_thresholds($self->{avSlowICAPConnections}));
  $self->add_perfdata(
      label => 'slow_connections',
      value => $self->{avSlowICAPConnections},
  );
}

