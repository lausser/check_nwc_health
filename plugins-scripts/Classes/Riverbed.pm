package Classes::Riverbed;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->implements_mib('STEELHEAD-MIB')) {
    bless $self, 'Classes::Riverbed::Steelhead';
    $self->debug('using Classes::Riverbed::Steelhead');
  } elsif ($self->implements_mib('STEELHEAD-EX-MIB')) {
    bless $self, 'Classes::Riverbed::SteelheadEX';
    $self->debug('using Classes::Riverbed::SteelheadEX');
  }
  if (ref($self) ne "Classes::Riverbed") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}

