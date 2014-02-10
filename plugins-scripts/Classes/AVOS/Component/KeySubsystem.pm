package Classes::AVOS::Component::KeySubsystem;
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
  foreach (qw(avLicenseDaysRemaining avVendorName)) {
    $self->{$_} = $self->get_snmp_object('BLUECOAT-AV-MIB', $_);
  }
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'license %s expires in %d days',
      $self->{avVendorName},
      $self->{avLicenseDaysRemaining});
  $self->set_thresholds(warning => '14:', critical => '7:');
  $self->add_message($self->check_thresholds($self->{avLicenseDaysRemaining}), $self->{info});
  $self->add_perfdata(
      label => sprintf('lifetime_%s', $self->{avVendorName}),
      value => $self->{avLicenseDaysRemaining},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[LICENSE_%s]\n", $self->{avVendorName};
  foreach (qw(avLicenseDaysRemaining avVendorName)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


