package CheckNwcHealth::SkyHigh;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->implements_mib('SKYHIGHSECURITY-SWG-MIB')) {
    $self->rebless('CheckNwcHealth::SkyHigh::SWG');
  }
  if (ref($self) ne "CheckNwcHealth::SkyHigh") {
    $self->init();
  }
}

