package CheckNwcHealth::Server::Linux::Component::CpuSubsystem;
our @ISA = qw(CheckNwcHealth::Server::Linux);
use strict;

sub new {
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my ($self) = @_;
  $self->{cpu_subsystem} =
      CheckNwcHealth::UCDMIB::Component::CpuSubsystem->new();
  $self->{load_subsystem} =
      CheckNwcHealth::UCDMIB::Component::LoadSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{cpu_subsystem}->check();
  $self->{load_subsystem}->check();
}

sub dump {
  my ($self) = @_;
  $self->{cpu_subsystem}->dump();
  $self->{load_subsystem}->dump();
}


1;
