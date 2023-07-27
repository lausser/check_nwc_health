package CheckNwcHealth::Nortel;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->implements_mib('S5-CHASSIS-MIB')) {
    bless $self, 'CheckNwcHealth::Nortel::S5';
    $self->debug('using CheckNwcHealth::Nortel::S5');
  } elsif ($self->implements_mib('RAPID-CITY-MIB')) {
    # synoptics wird von bay networks gekauft
    # bay networks wird von nortel gekauft
    # und alles was ich da an testdaten habe, ist muell. lauter
    # dreck aus einer rcPortTable, aber nix fan, nix temp, nix cpu
    bless $self, 'CheckNwcHealth::RAPIDCITYMIB';
    $self->debug('using CheckNwcHealth::RAPID-CITY-MIB');
  }
  if (ref($self) ne "CheckNwcHealth::Nortel") {
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


