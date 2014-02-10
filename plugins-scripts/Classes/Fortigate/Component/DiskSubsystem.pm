package Classes::Fortigate::Component::DiskSubsystem;
our @ISA = qw(Classes::Fortigate::Component::EnvironmentalSubsystem);

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
  $self->{fgSysDiskUsage} = 
      $self->get_snmp_object('FORTINET-FORTIGATE-MIB', 'fgSysDiskUsage');
  $self->{fgSysDiskCapacity} = 
      $self->get_snmp_object('FORTINET-FORTIGATE-MIB', 'fgSysDiskCapacity');
  $self->{usage} = $self->{fgSysDiskCapacity} ? 
      100 * $self->{fgSysDiskUsage} /  $self->{fgSysDiskCapacity} : undef;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking disks');
  $self->blacklist('di', '');
  if (! defined $self->{usage}) {
    $self->add_info(sprintf 'system has no disk');
    return;
  }
  $self->add_info(sprintf 'disk is %.2f%% full',
      $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}), $self->{info});
  $self->add_perfdata(
      label => 'disk_usage',
      value => $self->{usage},
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

