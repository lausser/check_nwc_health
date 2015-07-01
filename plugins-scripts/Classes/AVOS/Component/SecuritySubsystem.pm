package Classes::AVOS::Component::SecuritySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('BLUECOAT-AV-MIB', (qw(
      avVirusesDetected)));
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%d viruses detected',
      $self->{avVirusesDetected});
  $self->set_thresholds(warning => 1500, critical => 1500);
  $self->add_message($self->check_thresholds($self->{avVirusesDetected}));
  $self->add_perfdata(
      label => 'viruses',
      value => $self->{avVirusesDetected},
  );
}

