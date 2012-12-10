package NWC::CheckPoint::Firewall1::Component::SvnSubsystem;
our @ISA = qw(NWC::CheckPoint::Firewall1);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    cpus => [],
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
  my %params = @_;
  if ($self->mode =~ /device::svn::status/) {
    $self->{svnStatShortDescr} = $self->get_snmp_object('CHECKPOINT-MIB', 'svnStatShortDescr');
    $self->{svnStatLongDescr} = $self->get_snmp_object('CHECKPOINT-MIB', 'svnStatLongDescr');
  }
}

sub check {
  my $self = shift;
  my %params = @_;
  my $errorfound = 0;
  $self->add_info('checking svn');
  if ($self->mode =~ /device::svn::status/) {
    if ($self->{svnStatShortDescr} ne 'OK') {
      $self->add_message(CRITICAL,
          sprintf 'status of svn is %s', $self->{svnStatLongDescr});
    } else {
      $self->add_message(OK,
          sprintf 'status of svn is %s', $self->{svnStatLongDescr});
    }
  }
}

sub dump {
  my $self = shift;
  printf "[SVN]\n";
}

