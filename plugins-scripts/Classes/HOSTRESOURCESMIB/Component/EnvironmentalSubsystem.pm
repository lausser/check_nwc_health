package Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::HOSTRESOURCESMIB);
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
  $self->{disk_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::DiskSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{disk_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{disk_subsystem}->dump();
}

1;
