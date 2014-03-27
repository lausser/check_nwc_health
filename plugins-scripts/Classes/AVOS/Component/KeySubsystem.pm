package Classes::AVOS::Component::KeySubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('BLUECOAT-AV-MIB', (qw(
      avLicenseDaysRemaining avVendorName)));
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'license %s expires in %d days',
      $self->{avVendorName},
      $self->{avLicenseDaysRemaining});
  $self->set_thresholds(warning => '14:', critical => '7:');
  $self->add_message($self->check_thresholds($self->{avLicenseDaysRemaining}));
  $self->add_perfdata(
      label => sprintf('lifetime_%s', $self->{avVendorName}),
      value => $self->{avLicenseDaysRemaining},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}


