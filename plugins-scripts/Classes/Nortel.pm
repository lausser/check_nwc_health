package Classes::Nortel;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->implements_mib('S5-CHASSIS-MIB')) {
    bless $self, 'Classes::Nortel::S5';
    $self->debug('using Classes::Nortel::S5');
  } elsif ($self->implements_mib('RAPID-CITY-MIB')) {
    # synoptics wird von bay networks gekauft
    # bay networks wird von nortel gekauft
    # und alles was ich da an testdaten habe, ist muell. lauter
    # dreck aus einer rcPortTable, aber nix fan, nix temp, nix cpu
    bless $self, 'Classes::RAPIDCITYMIB';
    $self->debug('using Classes::RAPID-CITY-MIB');
  }
  if (ref($self) ne "Classes::Nortel") {
    $self->init();
  }
}

__END__

           cpu    mem
3510       -      -
450        -      -
4526gtx    x      x
4548       x      x
5632       x      x


