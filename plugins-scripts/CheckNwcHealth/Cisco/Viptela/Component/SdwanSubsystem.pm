package CheckNwcHealth::Cisco::Viptela::Component::SdwanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-SDWAN-BFD-MIB'} = {
      'bfdSummary' => '1.3.6.1.4.1.9.9.1002.1.1.5',
      'bfdSummaryBfdSessionsTotal' => '1.3.6.1.4.1.9.9.1002.1.1.5.1',
      'bfdSummaryBfdSessionsUp' => '1.3.6.1.4.1.9.9.1002.1.1.5.2',
      'bfdSummaryBfdSessionsMax' => '1.3.6.1.4.1.9.9.1002.1.1.5.3',
      'bfdSummaryBfdSessionsFlap' => '1.3.6.1.4.1.9.9.1002.1.1.5.4',
  };
  $self->get_snmp_objects("CISCO-SDWAN-BFD-MIB", qw(bfdSummaryBfdSessionsTotal bfdSummaryBfdSessionsUp));
  $self->{session_availability} = $self->{bfdSummaryBfdSessionsTotal} == 0 ? 0 : (
      $self->{bfdSummaryBfdSessionsUp} /
      $self->{bfdSummaryBfdSessionsTotal}
  ) * 100;
}

sub check {
  my ($self) = @_;
  if ($self->mode eq "device::sdwan::session::availability") {
    $self->add_info(sprintf "%d of %d sessions are up (%.2f%%)",
        $self->{bfdSummaryBfdSessionsUp},
        $self->{bfdSummaryBfdSessionsTotal},
        $self->{session_availability});
    $self->set_thresholds(metric => "session_availability",
        warning => "100:",
        critical => "50:");
    $self->add_message($self->check_thresholds(
        metric => "session_availability",
        value => $self->{session_availability}));
    $self->add_perfdata(
        label => 'session_availability',
        value => $self->{session_availability},
        uom => '%',
    );
  }
}

1;
