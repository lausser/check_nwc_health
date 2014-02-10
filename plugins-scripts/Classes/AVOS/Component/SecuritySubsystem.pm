package Classes::AVOS::Component::SecuritySubsystem;
our @ISA = qw(Classes::AVOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  foreach (qw(avVirusesDetected)) {
    $self->{$_} = $self->get_snmp_object('BLUECOAT-AV-MIB', $_);
  }
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%d viruses detected',
      $self->{avVirusesDetected});
  $self->set_thresholds(warning => 1500, critical => 1500);
  $self->add_message($self->check_thresholds($self->{avVirusesDetected}), $self->{info});
  $self->add_perfdata(
      label => 'viruses',
      value => $self->{avVirusesDetected},
      warning => $self->{warning},
      critical => $self->{critical},
  );

}

sub dump {
  my $self = shift;
  printf "[VIRUSES]\n";
  foreach (qw(avVirusesDetected)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


