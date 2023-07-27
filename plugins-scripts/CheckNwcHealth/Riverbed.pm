package CheckNwcHealth::Riverbed;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->implements_mib('STEELHEAD-MIB')) {
    bless $self, 'CheckNwcHealth::Riverbed::Steelhead';
    $self->debug('using CheckNwcHealth::Riverbed::Steelhead');
  } elsif ($self->implements_mib('STEELHEAD-EX-MIB')) {
    bless $self, 'CheckNwcHealth::Riverbed::SteelheadEX';
    $self->debug('using CheckNwcHealth::Riverbed::SteelheadEX');
  }
  if (ref($self) ne "CheckNwcHealth::Riverbed") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

