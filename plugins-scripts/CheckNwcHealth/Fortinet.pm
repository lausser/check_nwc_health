package CheckNwcHealth::Fortinet;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->implements_mib('FORTINET-FORTIMAIL-MIB')) {
    $self->rebless('CheckNwcHealth::Fortinet::Fortimail');
  } elsif ($self->implements_mib('FORTINET-FORTIGATE-MIB')) {
    $self->rebless('CheckNwcHealth::Fortinet::Fortigate');
  } elsif ($self->{productname} =~ /FortiMail/i) {
    $self->rebless('CheckNwcHealth::Fortinet::Fortimail');
  }
  if (ref($self) ne "CheckNwcHealth::Fortinet") {
    $self->init();
  } else {
    $self->no_such_model();
  }
}
