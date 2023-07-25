package CheckNwcHealth::Server::Linux::Component::MemSubsystem;
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
  $self->{mem_subsystem} =
      CheckNwcHealth::UCDMIB::Component::MemSubsystem->new();
  $self->{swap_subsystem} =
      CheckNwcHealth::UCDMIB::Component::SwapSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{mem_subsystem}->check();
  $self->{swap_subsystem}->check();
}

sub dump {
  my ($self) = @_;
  $self->{mem_subsystem}->dump();
  $self->{swap_subsystem}->dump();
}


1;
