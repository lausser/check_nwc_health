package Classes::Server::Linux::Component::CpuSubsystem;
our @ISA = qw(Classes::Server::Linux);
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
      Classes::UCDMIB::Component::CpuSubsystem->new();
  $self->{load_subsystem} =
      Classes::UCDMIB::Component::LoadSubsystem->new();
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
