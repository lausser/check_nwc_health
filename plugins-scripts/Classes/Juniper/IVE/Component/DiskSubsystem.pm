package Classes::Juniper::IVE::Component::DiskSubsystem;
our @ISA = qw(Classes::Juniper::IVE::Component::EnvironmentalSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  $self->{diskFullPercent} = 
      $self->get_snmp_object('JUNIPER-IVE-MIB', 'diskFullPercent');
}

sub check {
  my $self = shift;
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

