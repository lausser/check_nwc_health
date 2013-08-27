package NWC::Juniper::IVE::Component::DiskSubsystem;
our @ISA = qw(NWC::Juniper::IVE::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    disks => [],
    diskthresholds => [],
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
  my $disks = {};
  $self->{diskFullPercent} = 
      $self->get_snmp_object('JUNIPER-IVE-MIB', 'diskFullPercent');
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking disks');
  $self->blacklist('di', '');
  $self->add_info(sprintf 'disk is %.2f%% full',
      $self->{diskFullPercent});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{diskFullPercent}), $self->{info});
  $self->add_perfdata(
      label => 'disk_usage',
      value => $self->{diskFullPercent},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[DISK]\n";
  printf "info: %s\n", $self->{info};
}

